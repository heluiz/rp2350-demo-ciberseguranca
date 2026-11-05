"""Abre o iniciador Linux irmão e preserva mensagens de falha no terminal."""

from pathlib import Path
import subprocess
import sys


def abrir(caminho_atalho):
    atalho = Path(caminho_atalho)
    if not atalho.is_absolute() or "\x00" in str(atalho):
        raise ValueError("O atalho precisa ter um caminho local absoluto.")
    pasta = atalho.parent.resolve()
    if pasta != Path(__file__).resolve().parent:
        raise ValueError("Mantenha o atalho e ABRIR_NO_LINUX.py na mesma pasta da USB.")
    iniciador = pasta / "INICIAR_NO_LINUX.sh"
    if not iniciador.is_file():
        raise FileNotFoundError("INICIAR_NO_LINUX.sh nao encontrado ao lado do atalho.")
    resultado = subprocess.call(["sh", str(iniciador)], shell=False)
    return resultado if resultado >= 0 else 128 - resultado


def pausar_apos_falha():
    try:
        input("Pressione Enter para fechar...")
    except (EOFError, KeyboardInterrupt):
        pass


def main():
    try:
        if len(sys.argv) != 2:
            raise ValueError("Abra INICIAR_NO_LINUX.desktop na unidade USB.")
        resultado = abrir(sys.argv[1])
    except KeyboardInterrupt:
        resultado = 130
    except Exception as erro:
        print("ERRO ao iniciar a demonstracao:", erro, file=sys.stderr, flush=True)
        resultado = 1
    if resultado:
        print("A demonstracao terminou com codigo", resultado,
              file=sys.stderr, flush=True)
        pausar_apos_falha()
    return resultado


if __name__ == "__main__":
    raise SystemExit(main())
