"""Iniciador manual do SENTINEL em modo terminal."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from urllib.request import urlopen
from zipfile import BadZipFile, ZipFile

REVISAO = "5bc82b141a4361e6a688a7793fb83a9ade82bb95"
REPOSITORIO = "trab02_2026_2_12621cbs200"
URL = f"https://codeload.github.com/heluiz/{REPOSITORIO}/zip/{REVISAO}"


def preparar_codigo(raiz):
    app = raiz / f"{REPOSITORIO}-{REVISAO}"
    if (app / "main.py").is_file():
        return app
    print("Baixando a versão do SENTINEL...", flush=True)
    with tempfile.TemporaryDirectory(dir=raiz) as pasta:
        temporario = Path(pasta)
        zip_path = temporario / "sentinel.zip"
        with urlopen(URL, timeout=60) as resposta, zip_path.open("wb") as arquivo:
            shutil.copyfileobj(resposta, arquivo)
        with ZipFile(zip_path) as pacote:
            pacote.extractall(temporario)
        fontes = temporario / app.name
        for nome in ("main.py", "requirements.txt", "dados_exemplo/inventario_exemplo.json"):
            if not (fontes / nome).is_file():
                raise ValueError(f"Arquivo ausente no pacote: {nome}")
        fontes.rename(app)
    return app


def preparar_python(raiz, app):
    venv = raiz / f"venv-{sys.version_info.major}.{sys.version_info.minor}"
    python = venv / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    requisitos = app / "requirements.txt"
    hash_requisitos = hashlib.sha256(requisitos.read_bytes()).hexdigest()
    marca = venv / f"requirements-{hash_requisitos}.ok"
    if not python.is_file():
        subprocess.run([sys.executable, "-m", "venv", str(venv)], check=True)
    if not marca.is_file():
        print("Instalando as dependências do SENTINEL...", flush=True)
        subprocess.run(
            [str(python), "-m", "pip", "--disable-pip-version-check",
             "install", "-r", str(requisitos)],
            check=True,
        )
        marca.touch()
    return python


def main():
    if sys.version_info < (3, 11):
        raise ValueError("Instale o Python 3.11 ou mais recente.")
    if os.name == "nt":
        local = Path(os.environ["LOCALAPPDATA"])
    else:
        local = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    raiz = local / "SENTINEL_Pico"
    raiz.mkdir(parents=True, exist_ok=True)
    app = preparar_codigo(raiz)
    python = preparar_python(raiz, app)
    dados = raiz / "dados"
    dados.mkdir(exist_ok=True)
    inventario = dados / "inventario.json"
    antigo = local / "Ciberseguranca_T2_Demo" / "dados_demo" / "inventario.json"
    if not inventario.exists():
        origem = antigo if antigo.is_file() else app / "dados_exemplo/inventario_exemplo.json"
        shutil.copyfile(origem, inventario)
    ambiente = os.environ.copy()
    ambiente.pop("INVENTARIO_BANCO", None)
    ambiente["INVENTARIO_DADOS"] = str(inventario)
    ambiente["INVENTARIO_BASE_CVE"] = str(dados / "base_cve.json")
    return subprocess.call([str(python), str(app / "main.py")], cwd=app, env=ambiente)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, BadZipFile, subprocess.CalledProcessError) as erro:
        print(f"Falha ao abrir o SENTINEL: {erro}", file=sys.stderr)
        sys.exit(1)

