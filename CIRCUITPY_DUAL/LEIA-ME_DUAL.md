# Windows automático e Linux pelo iniciador da unidade

O programa completo e a abertura animada continuam nos dois sistemas. No Windows a placa pode iniciar a preparação automaticamente. No modo Linux ela fica azul, sem enviar qualquer tecla; você abre o iniciador na unidade USB. Não existe mais digitação no KRunner ou dependência de Konsole.

## Antes de trocar de computador

A placa não identifica o sistema operacional com segurança. Escolha o modo correspondente antes de retirar a placa:

- No Windows, abra `ESCOLHER_SISTEMA.cmd`: **1 — Windows automático**, **2 — Linux manual**, **3 — manual, sem digitação**.
- No Linux, abra um terminal na unidade e execute `sh ESCOLHER_SISTEMA.sh`; as escolhas são as mesmas.
- Também é possível editar `modo.txt`, deixando apenas `windows`, `linux` ou `manual`.

A escolha vale na próxima conexão e fica salva. Para levar a placa do Windows ao Linux, escolha **2 antes de desconectar**. O modo Windows envia comandos de Windows; ele não deve ser usado ao conectar em Linux. O modo Linux e o modo manual não enviam comandos em nenhum sistema.

## No Windows

Com o modo `windows` escolhido, conecte e aguarde: Executar → PowerShell → preparação → animação → menu. Mantenha o teclado brasileiro ABNT2 compatível com o firmware. As esperas continuam em 15 segundos antes do Executar, 1,5 segundo para o campo e 10 segundos para abrir o PowerShell, com 20 ms por caractere.

Se necessário, abra `INICIAR_NO_WINDOWS.cmd` na unidade. Ele verifica o preparador e usa o mesmo fluxo, sem depender da digitação USB.

## No Linux

1. Com o modo `linux` já escolhido, conecte a placa.
2. Abra **CIRCUITPY** no gerenciador de arquivos. Essa ação disponibiliza os arquivos da unidade, evitando depender de automontagem ao conectar.
3. Abra **INICIAR_NO_LINUX.desktop**. O nome exibido pode aparecer sem a extensão. Se o gerenciador perguntar, confirme a execução do iniciador que você acabou de abrir.
4. O iniciador abre um terminal do ambiente gráfico, verifica o pacote e executa a preparação, a animação e o programa.

O atalho usa `Terminal=true`, sem exigir KDE ou um nome fixo de terminal. Alguns gerenciadores podem abrir `.desktop` como texto ou impedir sua execução em uma unidade externa, especialmente no GNOME. Não há promessa de dois cliques em todos os ambientes; nesse caso, abra um terminal na pasta CIRCUITPY e execute:

```sh
sh INICIAR_NO_LINUX.sh
```

Esse comando funciona sem exigir permissão de execução na unidade FAT. O atalho e o iniciador calculam o próprio caminho: não dependem do nome do usuário, do diretório inicial do terminal ou de `/run/media` fixo.

São necessários Python 3.11 ou superior, venv e pip. Tk permite a animação; sem Tk, o programa continua no terminal. Se faltar Python/venv, o iniciador mostra orientação para a distribuição. Ele não executa sudo, não instala pacotes administrativos nem adiciona repositórios. No atalho, Python 3 precisa estar disponível para abrir o iniciador; se estiver ausente, use o comando acima para obter o diagnóstico.

A preparação permanece independente da interface gráfica: pode ser usada em Fedora, Ubuntu, Kali ou CachyOS com as dependências compatíveis. A aceitação do atalho depende do gerenciador de arquivos. A interface e o fluxo completo ainda não foram testados fisicamente nessas distribuições.

## Instalação, dados e atualização

O programa roda em Python nativo: Git, WSL e Docker não são necessários. A primeira preparação precisa de internet para a revisão verificada do GitHub e as bibliotecas NumPy/CVSS. As execuções seguintes reutilizam uma instalação válida e preservam os dados.

| Sistema | Pasta da demonstração |
|---|---|
| Windows | `%LOCALAPPDATA%\Ciberseguranca_T2_Demo` |
| Linux | `$XDG_DATA_HOME/Ciberseguranca_T2_Demo` ou `~/.local/share/Ciberseguranca_T2_Demo` |

Cada computador mantém seus próprios dados; a placa não transporta automaticamente alterações no inventário.

O pacote `CIRCUITPY_DUAL` atualiza uma placa com CircuitPython 10.0.3 e as bibliotecas pico-ducky já instaladas. Copie seu conteúdo para a raiz de CIRCUITPY, incluindo `CIBER_T2`. Preserve `boot.py`, `lib` e os demais arquivos existentes. O pacote começa em modo `manual`: confira todos os arquivos antes de selecionar o sistema. Não é necessário outro UF2. Formatar CIRCUITPY apaga os arquivos e as bibliotecas; o pacote de atualização não contém a instalação completa delas.

O antigo `payload_linux.dd` não faz parte desta versão. O modo Linux retorna antes de qualquer chamada ao teclado USB, mesmo se esse arquivo antigo ainda estiver na unidade.

## LED e diagnóstico

Azul indica espera, modo Linux ou manual. Amarelo indica envio de comandos Windows; verde indica que esse envio terminou, sem comprovar o resultado do programa. Vermelho indica erro da placa. Ao abrir manualmente o programa no Linux, o LED continua azul.

O registro Windows fica em `%TEMP%\Ciberseguranca_T2_preparacao.log`; no Linux, em `preparacao_linux.log` na pasta de dados da demonstração. Falhas anteriores ao início do preparador não aparecem nesses registros. Uma falha dentro do iniciador Linux mantém a mensagem disponível para leitura.

Referências: [especificação de arquivos .desktop](https://specifications.freedesktop.org/desktop-entry-spec/latest/), [execução e argumentos](https://specifications.freedesktop.org/desktop-entry-spec/latest/exec-variables.html).
