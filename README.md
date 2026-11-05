# RP2350 — demonstração de Cibersegurança

Adaptação do [pico-ducky](https://github.com/dbisu/pico-ducky) para a placa TENSTAR RP2350-USB, usada na apresentação do curso de Cibersegurança da UFU. Plugada no computador, a placa prepara e abre a demonstração do [Ciberseguranca_T2](https://github.com/heluiz/Ciberseguranca_T2) no Windows ou no Linux. Inclui seleção de sistema e LED WS2812 no GP22.

## Uso responsável

Projeto acadêmico de demonstração. Use apenas em computadores seus ou com autorização expressa do responsável.

No Windows, o payload abre o PowerShell e executa o preparador gravado na própria placa, depois de conferir o hash SHA256 dele. O preparador instala a aplicação numa pasta própria (`%LOCALAPPDATA%\Ciberseguranca_T2_Demo`), com ambiente virtual Python, e só se conecta ao GitHub (para baixar a aplicação) e ao PyPI (para as dependências). Ele não cria tarefas agendadas, não altera o Windows Defender nem outras proteções, e não envia dados do computador. No Linux e no modo manual, a placa não envia teclas.

## Conteúdo e uso

`CIRCUITPY_DUAL/` é o pacote final de atualização: firmware Python adaptado, seletores, payload Windows, iniciadores e preparadores. O arquivo `modo.txt` começa em `manual`. Os detalhes estão em [LEIA-ME_DUAL.md](CIRCUITPY_DUAL/LEIA-ME_DUAL.md).

O pacote pressupõe uma placa já preparada com CircuitPython 10.0.3, pico-ducky v4.0 WIN_BR e bibliotecas compatíveis. Não é uma imagem completa de instalação e não inclui `boot.py`, bibliotecas ou UF2. Preserve a instalação existente ao copiar o conteúdo do pacote para CIRCUITPY. Escolha o sistema antes de reconectar; a placa não identifica o sistema automaticamente.

- Windows: permite iniciar a preparação por USB ou por `INICIAR_NO_WINDOWS.cmd`; a digitação automática depende do layout brasileiro compatível com WIN_BR.
- Linux: não envia teclas; abra `INICIAR_NO_LINUX.desktop` ou execute `sh INICIAR_NO_LINUX.sh` em um terminal na unidade. Requer Python 3.11+, venv e pip; Tk é opcional para a animação.
- Manual: não envia teclas; os iniciadores continuam disponíveis.

A primeira preparação precisa de internet e baixa a aplicação na revisão fixa `a6ba203c8aed9670f76e2bba76a422322f134c59`, com verificação SHA256, além das dependências. Os dados existentes são preservados. A aplicação T2 não foi duplicada neste repositório.

## Créditos e licença

O firmware deriva do [dbisu/pico-ducky](https://github.com/dbisu/pico-ducky), de Dave Bailey (dbisu), copyright 2023, sob a GPLv2; os cabeçalhos originais foram preservados. Por isso, este repositório também é distribuído sob a [GPL-2.0](LICENSE). A adaptação e a integração são de Heluiz Tavares de Castro Filho (2026). A aplicação T2 e as dependências baixadas mantêm as próprias licenças.

## Verificação e limites

No Windows, o fluxo foi testado até a chegada ao menu da demonstração. O fluxo gráfico Linux não foi testado fisicamente em CachyOS, Fedora, Ubuntu, Kali ou no computador do docente; a aceitação de `.desktop` depende do ambiente. A instalação de Python ausente pelo WinGet foi testada por simulação.
