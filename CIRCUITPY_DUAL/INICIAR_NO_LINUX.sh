#!/bin/sh
set -eu

pasta=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
if [ -f "$pasta/CIBER_T2/PREPARAR_DEMO_LINUX.py" ]; then
    pasta="$pasta/CIBER_T2"
fi

orientar_python() {
    distribuicao=$(if [ -r /etc/os-release ]; then . /etc/os-release; printf '%s %s' "${ID-}" "${ID_LIKE-}"; fi)
    case " $distribuicao " in
        *debian*|*ubuntu*|*linuxmint*) printf '%s\n' 'Pacotes do sistema: sudo apt-get install python3 python3-venv python3-pip python3-tk' ;;
        *fedora*|*rhel*) printf '%s\n' 'Pacotes do sistema: sudo dnf install python3 python3-pip python3-tkinter' ;;
        *arch*) printf '%s\n' 'Pacotes do sistema: sudo pacman -S python python-pip tk' ;;
        *suse*) printf '%s\n' 'Pacotes do sistema: sudo zypper install python3 python3-pip python3-tk' ;;
        *) printf '%s\n' 'Solicite Python 3.11 ou superior com venv, pip e suporte Tk para esta distribuicao.' ;;
    esac
    printf '%s\n' 'Os pacotes da distribuicao precisam oferecer Python 3.11 ou superior; instalar o Python padrao antigo nao resolve. Nenhum comando de administrador foi executado.'
}

if ! command -v python3 >/dev/null 2>&1; then
    printf '%s\n' 'Python 3.11 ou superior nao foi encontrado.' >&2
    orientar_python >&2
    exit 1
fi
if ! python3 -I -c 'import sys;raise SystemExit(sys.version_info < (3,11))'; then
    printf '%s\n' 'Esta demonstracao precisa de Python 3.11 ou superior. Peça uma versao compativel para esta distribuicao.' >&2
    orientar_python >&2
    exit 1
fi

python3 -I - "$pasta" <<'PY'
import hashlib
from pathlib import Path
import re
import sys

pasta = Path(sys.argv[1])
nomes = {"PREPARAR_DEMO_LINUX.py", "INICIAR_NO_LINUX.sh", "ABERTURA_DEMO.py"}
try:
    hashes = {}
    for linha in (pasta / "SHA256SUMS").read_text(encoding="ascii").splitlines():
        if not linha:
            continue
        item = re.fullmatch(r"([0-9a-fA-F]{64}) [ *](.+)", linha)
        if not item or item[2] not in nomes or item[2] in hashes:
            raise ValueError("SHA256SUMS invalido")
        hashes[item[2]] = item[1].lower()
    if set(hashes) != nomes:
        raise ValueError("SHA256SUMS incompleto")
    for nome, esperado in hashes.items():
        if hashlib.sha256((pasta / nome).read_bytes()).hexdigest() != esperado:
            raise ValueError("Arquivo diferente do esperado: " + nome)
except (OSError, ValueError) as erro:
    print("ERRO: " + str(erro) + ". Use os arquivos da mesma versao do kit.", file=sys.stderr)
    raise SystemExit(1)
PY

exec python3 -I -X utf8 "$pasta/PREPARAR_DEMO_LINUX.py"
