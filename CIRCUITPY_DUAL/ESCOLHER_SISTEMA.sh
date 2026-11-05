#!/bin/sh
set -eu
pasta=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
printf '%s\n' 'Escolha o sistema do proximo computador:' '1 - Windows automatico' '2 - Linux manual: abrir o iniciador na unidade USB' '3 - Manual, sem digitacao automatica'
IFS= read -r opcao
case "$opcao" in
    1) modo=windows ;;
    2) modo=linux ;;
    3) modo=manual ;;
    *) printf '%s\n' 'Opcao invalida; modo preservado.' >&2; exit 1 ;;
esac
if [ -L "$pasta/modo.txt" ]; then
    printf '%s\n' 'modo.txt e um link; arquivo preservado.' >&2
    exit 1
fi
printf '%s\n' "$modo" > "$pasta/modo.txt"
printf '%s\n' 'Modo salvo. Desconecte e conecte a placa no sistema escolhido.'
