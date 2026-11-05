"""Prepara o programa completo no Linux, com dados e dependências do usuário."""

import hashlib
import logging
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from urllib.request import urlopen
import zipfile


COMMIT = "a6ba203c8aed9670f76e2bba76a422322f134c59"
HASH_ZIP = "d2fc51a2bedab9c4c44c5d0e70be568730426a6f666a2b7649c6f728424b635f"
URL_ZIP = f"https://codeload.github.com/heluiz/Ciberseguranca_T2/zip/{COMMIT}"
ARQUIVOS_USB = {"PREPARAR_DEMO_LINUX.py", "INICIAR_NO_LINUX.sh", "ABERTURA_DEMO.py"}
LOG = logging.getLogger("ciberseguranca_demo")
CODIGO_DEPENDENCIAS = (
    'import numpy,cvss;from importlib.metadata import version;'
    'v=tuple(map(int,numpy.__version__.split(".")[:2]));'
    'assert (1,26)<=v<(3,0);assert version("cvss")=="3.6";'
    'print("NumPy "+numpy.__version__+"; CVSS "+version("cvss"))'
)


def verificar_pacote(pasta):
    hashes = {}
    for linha in (pasta / "SHA256SUMS").read_text(encoding="ascii").splitlines():
        if not linha:
            continue
        item = re.fullmatch(r"([0-9a-fA-F]{64}) [ *](.+)", linha)
        if not item or item[2] not in ARQUIVOS_USB or item[2] in hashes:
            raise RuntimeError("SHA256SUMS inválido. Use os arquivos da mesma versão do kit.")
        hashes[item[2]] = item[1].lower()
    if set(hashes) != ARQUIVOS_USB:
        raise RuntimeError("SHA256SUMS incompleto. Use os arquivos da mesma versão do kit.")
    for nome, esperado in hashes.items():
        if hashlib.sha256((pasta / nome).read_bytes()).hexdigest() != esperado:
            raise RuntimeError(f"Arquivo USB diferente do esperado: {nome}. Preparação interrompida.")


def pasta_instalacao():
    configurada = os.environ.get("XDG_DATA_HOME", "")
    base = Path(configurada) if configurada and Path(configurada).is_absolute() else Path.home() / ".local" / "share"
    return base / "Ciberseguranca_T2_Demo"


def recusar_link(caminho):
    if caminho.is_symlink():
        raise RuntimeError(f"Caminho simbólico inesperado; nenhum arquivo foi substituído: {caminho}")


def preparar_raiz(raiz):
    marcador = raiz / ".demo_ciberseguranca_t2"
    recusar_link(raiz)
    recusar_link(marcador)
    if raiz.exists():
        if not marcador.is_file() or marcador.read_text(encoding="ascii").strip() != COMMIT:
            raise RuntimeError(f"A pasta já existe sem a identificação desta demo: {raiz}. Os arquivos foram preservados.")
    else:
        raiz.mkdir(parents=True)
        marcador.write_text(COMMIT + "\n", encoding="ascii")


def baixar_arquivo(url, destino):
    for tentativa in range(2):
        try:
            with urlopen(url, timeout=30) as resposta, destino.open("wb") as arquivo:
                if not resposta.geturl().startswith("https://"):
                    raise RuntimeError("O download não permaneceu em HTTPS.")
                prazo, tamanho = time.monotonic() + 120, 0
                while True:
                    bloco = resposta.read(65536)
                    if not bloco:
                        break
                    tamanho += len(bloco)
                    if tamanho > 20 * 1024 * 1024 or time.monotonic() > prazo:
                        raise RuntimeError("O download excedeu o tamanho ou tempo esperado.")
                    arquivo.write(bloco)
            return
        except OSError:
            if tentativa:
                raise
            LOG.warning("O download falhou; repetindo uma vez.")


def extrair_projeto(arquivo_zip, destino):
    prefixo = f"Ciberseguranca_T2-{COMMIT}"
    if not destino.is_dir() or any(destino.iterdir()):
        raise RuntimeError("A extração precisa de uma pasta temporária vazia.")
    with zipfile.ZipFile(arquivo_zip) as arquivo:
        itens = arquivo.infolist()
        if len(itens) > 5000 or sum(item.file_size for item in itens) > 100 * 1024 * 1024:
            raise RuntimeError("Tamanho inesperado no ZIP do projeto.")
        for item in itens:
            partes = PurePosixPath(item.filename).parts
            if (not partes or partes[0] != prefixo or ".." in partes
                    or "\\" in item.filename or PurePosixPath(item.filename).is_absolute()
                    or stat.S_ISLNK(item.external_attr >> 16)):
                raise RuntimeError("Caminho inesperado no ZIP; nada foi extraído.")
        arquivo.extractall(destino)
    projeto = destino / prefixo
    for nome in ("main.py", "requirements.txt", "dados_exemplo/inventario_exemplo.json", "base_cve/kev.json"):
        if not (projeto / nome).is_file():
            raise RuntimeError(f"Fonte incompleta no ZIP: {nome}.")
    return projeto


def preparar(pasta, raiz):
    aplicacao, dados, ambiente = raiz / "aplicacao", raiz / "dados_demo", raiz / ".venv"
    for caminho in (aplicacao, dados, ambiente, raiz / "ABERTURA_DEMO.py"):
        recusar_link(caminho)
    LOG.info("Instalação e dados deste usuário: %s", raiz)
    LOG.info("Python %s: %s", sys.version.split()[0], sys.executable)
    LOG.info("Git, WSL e Docker não são necessários para esta execução nativa no Linux.")
    marcador_fonte = aplicacao / ".demo_commit"
    recusar_link(marcador_fonte)
    if aplicacao.exists():
        if not marcador_fonte.is_file() or marcador_fonte.read_text(encoding="ascii").strip() != COMMIT:
            raise RuntimeError("A pasta aplicacao existe sem a identificação esperada. Os arquivos foram preservados.")
        LOG.info("Fonte verificada já instalada; reutilizando.")
    else:
        LOG.info("Baixando a revisão verificada do projeto...")
        with tempfile.TemporaryDirectory(prefix="download_", dir=raiz) as temporaria:
            temporario = Path(temporaria)
            arquivo_zip = temporario / "projeto.zip"
            baixar_arquivo(URL_ZIP, arquivo_zip)
            if hashlib.sha256(arquivo_zip.read_bytes()).hexdigest() != HASH_ZIP:
                raise RuntimeError("O ZIP não corresponde ao SHA256 esperado; nenhum código baixado foi executado.")
            destino = temporario / "fontes"
            destino.mkdir()
            projeto = extrair_projeto(arquivo_zip, destino)
            (projeto / ".demo_commit").write_text(COMMIT + "\n", encoding="ascii")
            projeto.rename(aplicacao)
    for nome in ("main.py", "requirements.txt", "dados_exemplo/inventario_exemplo.json", "base_cve/kev.json"):
        recusar_link(aplicacao / nome)
        if not (aplicacao / nome).is_file():
            raise RuntimeError(f"Fonte instalada incompleta: {nome}. Os arquivos foram preservados.")
    if not ambiente.exists():
        LOG.info("Criando o ambiente Python do usuário...")
        try:
            subprocess.run([sys.executable, "-I", "-m", "venv", str(ambiente)], check=True, timeout=300)
        except subprocess.CalledProcessError as erro:
            raise RuntimeError("Não foi possível criar a .venv. No Ubuntu/Debian, peça a instalação de python3-venv; no Fedora, de python3-pip. A pasta parcial foi preservada.") from erro
    python = ambiente / "bin" / "python"
    if not python.is_file():
        raise RuntimeError(f"Ambiente virtual incompleto: {ambiente}. Corrija essa pasta antes de repetir.")
    versao = subprocess.run([str(python), "-I", "-c",
                            "import sys;from pathlib import Path;assert sys.version_info >= (3,11);assert sys.platform == 'linux';assert sys.prefix != sys.base_prefix;assert Path(sys.prefix).resolve() == Path(sys.argv[1]).resolve()",
                            str(ambiente)], timeout=30)
    if versao.returncode:
        raise RuntimeError("O ambiente virtual existente não tem Python Linux 3.11 ou superior; ele foi preservado.")
    LOG.info("Verificando NumPy e CVSS...")
    consulta = subprocess.run([str(python), "-I", "-c", CODIGO_DEPENDENCIAS], capture_output=True, text=True, timeout=30)
    if consulta.returncode:
        LOG.info("Instalando apenas as dependências da demonstração, dentro da .venv...")
        subprocess.run([str(python), "-I", "-m", "pip", "--isolated", "--disable-pip-version-check", "install",
                        "--no-input", "--index-url", "https://pypi.org/simple", "--only-binary=:all:",
                        "-r", str(aplicacao / "requirements.txt")], check=True, timeout=600)
        consulta = subprocess.run([str(python), "-I", "-c", CODIGO_DEPENDENCIAS], capture_output=True, text=True, timeout=30)
        if consulta.returncode:
            raise RuntimeError("As dependências não passaram na verificação: " + consulta.stderr.strip())
    LOG.info(consulta.stdout.strip())
    dados.mkdir(exist_ok=True)
    for origem, nome in (("dados_exemplo/inventario_exemplo.json", "inventario.json"), ("base_cve/kev.json", "base_cve.json")):
        destino = dados / nome
        recusar_link(destino)
        if not destino.exists():
            shutil.copyfile(aplicacao / origem, destino)
    shutil.copyfile(pasta / "ABERTURA_DEMO.py", raiz / "ABERTURA_DEMO.py")
    LOG.info("Preparação concluída. Abrindo animação e menu do programa...")
    return python


def main():
    try:
        if sys.platform != "linux":
            raise RuntimeError("No Windows, abra INICIAR_NO_WINDOWS.cmd.")
        if sys.version_info < (3, 11):
            raise RuntimeError("É necessário Python 3.11 ou superior. Peça a instalação de uma versão compatível.")
        pasta = Path(__file__).resolve().parent
        verificar_pacote(pasta)
        raiz = pasta_instalacao()
        preparar_raiz(raiz)
        arquivo_log = raiz / "preparacao_linux.log"
        recusar_link(arquivo_log)
        logging.basicConfig(level=logging.INFO, format="%(message)s", handlers=[
            logging.StreamHandler(sys.stdout), logging.FileHandler(arquivo_log, encoding="utf-8")])
        LOG.info("Log da preparação: %s", arquivo_log)
        python = preparar(pasta, raiz)
        return subprocess.call([str(python), "-I", "-X", "utf8", str(raiz / "ABERTURA_DEMO.py")], cwd=raiz)
    except KeyboardInterrupt:
        print("\nDemonstração interrompida pelo usuário.", file=sys.stderr)
        return 0
    except Exception as erro:
        print(f"\nERRO: {type(erro).__name__}: {erro}", file=sys.stderr)
        LOG.error("Preparação interrompida: %s", erro)
        if sys.stdin.isatty():
            try:
                input("Pressione Enter para fechar... ")
            except (EOFError, KeyboardInterrupt):
                pass
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
