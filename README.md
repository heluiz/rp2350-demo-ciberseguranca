# RP2350 — demonstração de Cibersegurança

Cópia organizada para repositório **privado**, com a adaptação do pico-ducky para a TENSTAR RP2350-USB e os iniciadores da demonstração do [Ciberseguranca_T2](https://github.com/heluiz/Ciberseguranca_T2). O trabalho de integração inclui seleção de sistema, LED WS2812 em GP22 e preparação da aplicação em Windows e Linux.

## Conteúdo e uso

`CIRCUITPY_DUAL/` é o pacote final de atualização: firmware Python adaptado, seletores, payload Windows, iniciadores e preparadores. O arquivo `modo.txt` começa em `manual`. Os detalhes estão em [LEIA-ME_DUAL.md](CIRCUITPY_DUAL/LEIA-ME_DUAL.md).

O pacote pressupõe uma placa já preparada com CircuitPython 10.0.3, pico-ducky v4.0 WIN_BR e bibliotecas compatíveis. Não é uma imagem completa de instalação e não inclui `boot.py`, bibliotecas ou UF2. Preserve a instalação existente ao copiar o conteúdo do pacote para CIRCUITPY. Escolha o sistema antes de reconectar; a placa não identifica o sistema automaticamente.

- Windows: permite iniciar a preparação por USB ou por `INICIAR_NO_WINDOWS.cmd`; a digitação automática depende do layout brasileiro compatível com WIN_BR.
- Linux: não envia teclas; abra `INICIAR_NO_LINUX.desktop` ou execute `sh INICIAR_NO_LINUX.sh` em um terminal na unidade. Requer Python 3.11+, venv e pip; Tk é opcional para a animação.
- Manual: não envia teclas; os iniciadores continuam disponíveis.

A primeira preparação precisa de internet e baixa a aplicação na revisão fixa `a6ba203c8aed9670f76e2bba76a422322f134c59`, com verificação SHA256, além das dependências. Os dados existentes são preservados. A aplicação T2 não foi duplicada neste repositório.

## Créditos e licença existente

O firmware deriva de [dbisu/pico-ducky](https://github.com/dbisu/pico-ducky), de Dave Bailey (dbisu), copyright 2023, identificado nos arquivos como GPLv2. Os cabeçalhos originais foram preservados e a cópia local existente da licença foi incluída em [LICENSE.pico-ducky](LICENSE.pico-ducky).

Esta organização não atribui uma nova licença geral ao código de integração ou à aplicação T2. A aplicação e as dependências continuam com seus respectivos avisos e condições.

## Verificação e limites

A cópia foi conferida por hashes contra o pacote local final, sem executar firmware, payload ou preparadores. Os arquivos de integridade fornecidos foram preservados.

O registro anterior confirmou a chegada ao menu no Windows deste computador. O fluxo gráfico Linux não foi testado fisicamente em CachyOS, Fedora, Ubuntu, Kali ou no computador do docente; a aceitação de `.desktop` depende do ambiente. A instalação de Python ausente pelo WinGet foi testada por simulação.

Backups privados de firmware, dumps, logs, caches e a cópia da aplicação foram excluídos desta preparação.
