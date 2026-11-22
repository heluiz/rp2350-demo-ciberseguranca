# RP2350 — demonstração de Cibersegurança

Projeto para a placa TENSTAR RP2350-USB, usada na apresentação do curso de Cibersegurança da UFU. O iniciador manual abre o menu de terminal do [trabalho atual (SENTINEL)](https://github.com/heluiz/trab02_2026_2_12621cbs200) no computador.

## Abrir o SENTINEL atual

1. Baixe [ABRIR-SENTINEL-PICO.cmd](CIRCUITPY_DUAL/ABRIR-SENTINEL-PICO.cmd) e [abrir_sentinel.py](CIRCUITPY_DUAL/abrir_sentinel.py) e coloque os dois arquivos na raiz da unidade `CIRCUITPY`. Não é preciso formatar a placa nem reinstalar o CircuitPython.
2. Se a placa estiver configurada para iniciar a demonstração antiga ao conectar, deixe apenas `manual` no arquivo `modo.txt`. Ejete a unidade antes de desconectar. A configuração vale na próxima conexão.
3. No Windows, dê dois cliques em `ABRIR-SENTINEL-PICO.cmd`. No Linux, abra um terminal na raiz da unidade e execute `python3 abrir_sentinel.py`.

É necessário Python 3.11 ou mais recente, com `venv` e `pip`. A primeira execução precisa de internet para baixar a revisão [`5bc82b1`](https://github.com/heluiz/trab02_2026_2_12621cbs200/commit/5bc82b141a4361e6a688a7793fb83a9ade82bb95) do SENTINEL e instalar as dependências. O iniciador reutiliza a instalação nas próximas execuções.

O inventário fica no computador, na pasta `SENTINEL_Pico/dados` dentro de `%LOCALAPPDATA%` no Windows ou de `${XDG_DATA_HOME:-~/.local/share}` no Linux. Se houver um inventário da demonstração anterior, o iniciador copia esse arquivo na primeira execução. A versão web tem [instruções próprias](https://github.com/heluiz/trab02_2026_2_12621cbs200#1-versão-web-no-windows).

## Demonstração anterior

A demonstração original, baseada no [pico-ducky](https://github.com/dbisu/pico-ducky), abre uma revisão fixa do [Ciberseguranca_T2](https://github.com/heluiz/Ciberseguranca_T2). Inclui seleção de sistema e LED WS2812 no GP22.

## Uso responsável

Projeto acadêmico de demonstração. Use apenas em computadores seus ou com autorização expressa do responsável.

No Windows, o payload abre o PowerShell e executa o preparador gravado na própria placa, depois de conferir o hash SHA256 dele. O preparador instala a aplicação numa pasta própria (`%LOCALAPPDATA%\Ciberseguranca_T2_Demo`), com ambiente virtual Python, e só se conecta ao GitHub (para baixar a aplicação) e ao PyPI (para as dependências). Ele não cria tarefas agendadas, não altera o Windows Defender nem outras proteções, e não envia dados do computador. No Linux e no modo manual, a placa não envia teclas.

## Conteúdo e uso

`CIRCUITPY_DUAL/` contém os arquivos da demonstração anterior: firmware Python adaptado, seletores, payload Windows, iniciadores e preparadores. O arquivo `modo.txt` começa em `manual`. Os detalhes estão em [LEIA-ME_DUAL.md](CIRCUITPY_DUAL/LEIA-ME_DUAL.md).

O pacote pressupõe uma placa já preparada com CircuitPython 10.0.3, pico-ducky v4.0 WIN_BR e bibliotecas compatíveis. Não é uma imagem completa de instalação e não inclui `boot.py`, bibliotecas ou UF2. Preserve a instalação existente ao copiar o conteúdo do pacote para CIRCUITPY. Escolha o sistema antes de reconectar; a placa não identifica o sistema automaticamente.

- Windows: permite iniciar a preparação por USB ou por `INICIAR_NO_WINDOWS.cmd`; a digitação automática depende do layout brasileiro compatível com WIN_BR.
- Linux: não envia teclas; abra `INICIAR_NO_LINUX.desktop` ou execute `sh INICIAR_NO_LINUX.sh` em um terminal na unidade. Requer Python 3.11+, venv e pip; Tk é opcional para a animação.
- Manual: não envia teclas; os iniciadores continuam disponíveis.

A primeira preparação precisa de internet e baixa a aplicação na revisão fixa `a6ba203c8aed9670f76e2bba76a422322f134c59`, com verificação SHA256, além das dependências. Os dados existentes são preservados. A aplicação T2 não foi duplicada neste repositório.

## Créditos e licença

O firmware deriva do [dbisu/pico-ducky](https://github.com/dbisu/pico-ducky), de Dave Bailey (dbisu), copyright 2023, sob a GPLv2; os cabeçalhos originais foram preservados. Por isso, este repositório também é distribuído sob a [GPL-2.0](LICENSE). A adaptação e a integração são de Heluiz Tavares de Castro Filho (2026). A aplicação T2 e as dependências baixadas mantêm as próprias licenças.

## Verificação da demonstração anterior

No Windows, o fluxo foi testado até a chegada ao menu da demonstração. O fluxo gráfico Linux não foi testado fisicamente em CachyOS, Fedora, Ubuntu, Kali ou no computador do docente; a aceitação de `.desktop` depende do ambiente. A instalação de Python ausente pelo WinGet foi testada por simulação.

