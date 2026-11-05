# Ciberseguranca T2: instalacao visivel para o usuario atual, Windows PowerShell 5.1.
# Fonte fixa: https://github.com/heluiz/Ciberseguranca_T2/tree/a6ba203c8aed9670f76e2bba76a422322f134c59
function Testar-Comando {
    param([string]$Executavel, [string]$Argumentos, [int]$LimiteMs = 6000)
    $processo = New-Object System.Diagnostics.Process
    $processo.StartInfo.FileName = $Executavel
    $processo.StartInfo.Arguments = $Argumentos
    $processo.StartInfo.UseShellExecute = $false
    $processo.StartInfo.CreateNoWindow = $true
    $processo.StartInfo.RedirectStandardInput = $true
    $processo.StartInfo.RedirectStandardOutput = $true
    $processo.StartInfo.RedirectStandardError = $true
    try {
        $null = $processo.Start()
        $processo.StandardInput.Close()
        $saida = $processo.StandardOutput.ReadToEndAsync()
        $erro = $processo.StandardError.ReadToEndAsync()
        if (-not $processo.WaitForExit($LimiteMs)) {
            $processo.Kill()
            return [pscustomobject]@{ Codigo = -1; Saida = 'Verificacao excedeu o tempo limite.' }
        }
        $processo.WaitForExit()
        return [pscustomobject]@{ Codigo = $processo.ExitCode; Saida = ($saida.Result + $erro.Result).Replace([string][char]0, '').Trim() }
    } catch {
        return [pscustomobject]@{ Codigo = -1; Saida = $_.Exception.Message }
    } finally {
        $processo.Dispose()
    }
}

function Testar-Python {
    param([string]$Executavel)
    if (-not (Test-Path -LiteralPath $Executavel -PathType Leaf)) { return $null }
    $teste = Testar-Comando $Executavel '-I -c "import sys,venv,ensurepip;print(str(sys.version_info.major)+\".\"+str(sys.version_info.minor)+\".\"+str(sys.version_info.micro)+\"|\"+sys.platform)"'
    if ($teste.Codigo -eq 0 -and $teste.Saida -match '^([0-9]+\.[0-9]+\.[0-9]+)\|win32$') {
        $versao = [version]$Matches[1]
        if ($versao -ge [version]'3.11') { return [pscustomobject]@{ Executavel = $Executavel; Versao = $versao } }
    }
    return $null
}

function Obter-Python {
    $candidatos = @()
    foreach ($chave in @('HKCU:\Software\Python\PythonCore\*\InstallPath', 'HKLM:\Software\Python\PythonCore\*\InstallPath', 'HKLM:\Software\WOW6432Node\Python\PythonCore\*\InstallPath')) {
        foreach ($item in @(Get-ItemProperty -Path $chave -ErrorAction SilentlyContinue)) {
            if ($item.ExecutablePath) { $candidatos += $item.ExecutablePath }
            elseif ($item.'(default)') { $candidatos += Join-Path $item.'(default)' 'python.exe' }
        }
    }
    $pacotes = @(Get-AppxPackage -Name 'PythonSoftwareFoundation.Python.3.*' -ErrorAction SilentlyContinue)
    foreach ($pacote in $pacotes) {
        $nomeAlias = 'python' + ($pacote.Name -replace '^PythonSoftwareFoundation.Python\.', '') + '.exe'
        $aliasPython = Get-Command $nomeAlias -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($aliasPython) { $candidatos += $aliasPython.Source }
    }
    foreach ($nome in @('python.exe', 'python3.exe')) {
        foreach ($comando in @(Get-Command $nome -CommandType Application -All -ErrorAction SilentlyContinue)) {
            # O alias da Store so e testado quando um pacote Python real foi confirmado.
            if ($comando.Source -notmatch '\\Microsoft\\WindowsApps\\' -or $pacotes.Count -gt 0) { $candidatos += $comando.Source }
        }
    }
    $candidatos += @(Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Python\Python*\python.exe", "$env:ProgramFiles\Python*\python.exe" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    foreach ($caminho in @($candidatos | Select-Object -Unique)) {
        $python = Testar-Python $caminho
        if ($python) { return $python }
    }
    return $null
}

function Garantir-Python {
    $python = Obter-Python
    if ($python) { return $python }
    Write-Host 'Python Windows 3.11 ou superior ausente. Instalando Python 3.13 para este usuario...' -ForegroundColor Yellow
    $winget = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $winget) { throw 'WinGet ausente. Instale Python 3.13 pelo python.org (inclua pip e Tcl/Tk) ou atualize o Instalador de Aplicativos da Microsoft Store; depois tente novamente.' }
    & $winget.Source install --id Python.Python.3.13 --exact --source winget --scope user --accept-source-agreements --accept-package-agreements --disable-interactivity | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "WinGet nao concluiu a instalacao (codigo $LASTEXITCODE). Leia a mensagem acima. Se houver bloqueio administrativo ou reinicio pendente, resolva-o normalmente e execute novamente." }
    $python = Obter-Python
    if (-not $python) { throw 'A instalacao terminou, mas Python compativel ainda nao foi encontrado. Abra outro PowerShell e tente novamente; nao foi alterada nenhuma politica de seguranca.' }
    return $python
}

function Preparar-Demo {
    $ErrorActionPreference = 'Stop'
    $raiz = Join-Path $env:LOCALAPPDATA 'Ciberseguranca_T2_Demo'
    $commit = 'a6ba203c8aed9670f76e2bba76a422322f134c59'
    $hashZip = 'D2FC51A2BEDAB9C4C44C5D0E70BE568730426A6F666A2B7649C6F728424B635F'
    $aplicacao = Join-Path $raiz 'aplicacao'
    $dados = Join-Path $raiz 'dados_demo'
    $venv = Join-Path $raiz '.venv'
    $pythonVenv = Join-Path $venv 'Scripts\python.exe'
    $marcador = Join-Path $raiz '.demo_ciberseguranca_t2'
    Write-Host ''
    Write-Host '  CIBERSEGURANCA T2 - PREPARACAO DA DEMONSTRACAO' -ForegroundColor Cyan
    Write-Host "  Instalacao e dados deste usuario: $raiz"
    Write-Progress -Activity 'Preparando Ciberseguranca T2' -Status 'Verificando Windows, Git e WSL' -PercentComplete 5
    foreach ($item in @(@('Git', 'git.exe', '--version'), @('WSL', 'wsl.exe', '--list --quiet'))) {
        $comando = Get-Command $item[1] -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($comando) {
            $teste = Testar-Comando $comando.Source $item[2]
            if ($teste.Codigo -eq 0 -and $teste.Saida) { Write-Host ("  {0}: {1}" -f $item[0], ($teste.Saida -replace '[\r\n]+', '; ')) }
            else { Write-Host "  $($item[0]): nao configurado/disponivel. Opcional nesta demonstracao." }
        } else { Write-Host "  $($item[0]): ausente. Opcional nesta demonstracao." }
    }
    Write-Host '  O programa completo roda em Python nativo; Git, WSL e Docker nao sao necessarios.'
    Write-Progress -Activity 'Preparando Ciberseguranca T2' -Status 'Verificando Python 3.11 ou superior' -PercentComplete 15
    $python = Garantir-Python
    Write-Host "  Python $($python.Versao): $($python.Executavel)"
    if (Test-Path -LiteralPath $raiz) {
        if (-not (Test-Path -LiteralPath $marcador -PathType Leaf) -or (Get-Content -LiteralPath $marcador -Raw).Trim() -ne $commit) { throw "A pasta $raiz ja existe e nao pertence a esta versao da demo. Nenhum arquivo foi substituido. Escolha manualmente outro destino para a pasta existente antes de repetir." }
    } else {
        $null = New-Item -ItemType Directory -Path $raiz
        [System.IO.File]::WriteAllText($marcador, $commit, [System.Text.Encoding]::ASCII)
    }
    Write-Progress -Activity 'Preparando Ciberseguranca T2' -Status 'Obtendo a versao verificada do projeto' -PercentComplete 30
    $marcadorFonte = Join-Path $aplicacao '.demo_commit'
    if (Test-Path -LiteralPath $aplicacao) {
        if (-not (Test-Path -LiteralPath $marcadorFonte -PathType Leaf) -or (Get-Content -LiteralPath $marcadorFonte -Raw).Trim() -ne $commit) { throw 'A pasta aplicacao existe sem a identificacao esperada. Os arquivos foram preservados. Corrija a pasta antes de repetir.' }
        Write-Host "  Fonte do projeto ja instalada: $commit"
    } else {
        $temporario = Join-Path $raiz ('download_' + [guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $temporario
        $arquivoZip = Join-Path $temporario 'projeto.zip'
        $protocolo = [System.Net.ServicePointManager]::SecurityProtocol
        try {
            [System.Net.ServicePointManager]::SecurityProtocol = $protocolo -bor [System.Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -UseBasicParsing -Uri "https://codeload.github.com/heluiz/Ciberseguranca_T2/zip/$commit" -OutFile $arquivoZip -TimeoutSec 120
        } finally { [System.Net.ServicePointManager]::SecurityProtocol = $protocolo }
        if ((Get-FileHash -LiteralPath $arquivoZip -Algorithm SHA256).Hash -ne $hashZip) { throw 'O ZIP baixado nao corresponde ao SHA256 verificado. Instalacao interrompida; nenhum codigo baixado foi executado.' }
        Expand-Archive -LiteralPath $arquivoZip -DestinationPath $temporario
        $extraido = Join-Path $temporario "Ciberseguranca_T2-$commit"
        if (-not (Test-Path -LiteralPath (Join-Path $extraido 'main.py') -PathType Leaf)) { throw 'O arquivo baixado nao contem o programa esperado.' }
        $origemAbsoluta = (Resolve-Path -LiteralPath $extraido).ProviderPath
        $temporarioAbsoluto = (Resolve-Path -LiteralPath $temporario).ProviderPath.TrimEnd('\') + '\'
        $raizAbsoluta = (Resolve-Path -LiteralPath $raiz).ProviderPath.TrimEnd('\') + '\'
        $destinoAbsoluto = [System.IO.Path]::GetFullPath($aplicacao)
        if (-not $origemAbsoluta.StartsWith($temporarioAbsoluto, [System.StringComparison]::OrdinalIgnoreCase) -or -not $destinoAbsoluto.StartsWith($raizAbsoluta, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Caminhos de movimentacao fora das pastas autorizadas. Preparacao interrompida.' }
        Move-Item -LiteralPath $origemAbsoluta -Destination $destinoAbsoluto
        [System.IO.File]::WriteAllText($marcadorFonte, $commit, [System.Text.Encoding]::ASCII)
    }
    foreach ($arquivo in @('main.py', 'requirements.txt', 'dados_exemplo\inventario_exemplo.json', 'base_cve\kev.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $aplicacao $arquivo) -PathType Leaf)) { throw "Fonte incompleta: $arquivo. Os arquivos existentes foram preservados." }
    }
    Write-Progress -Activity 'Preparando Ciberseguranca T2' -Status 'Preparando ambiente Python isolado' -PercentComplete 50
    if (-not (Test-Path -LiteralPath $venv)) {
        & $python.Executavel -I -m venv $venv | Out-Host
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar o ambiente virtual. Confira a mensagem acima e o espaco livre.' }
    }
    if (-not (Testar-Python $pythonVenv)) { throw "O ambiente virtual $venv esta incompleto ou incompativel. Ele foi preservado; corrija-o manualmente antes de repetir." }
    Write-Progress -Activity 'Preparando Ciberseguranca T2' -Status 'Verificando NumPy e CVSS; instalando o que faltar' -PercentComplete 65
    $codigoDeps = 'import numpy,cvss;from importlib.metadata import version;v=tuple(map(int,numpy.__version__.split(".")[:2]));assert (1,26)<=v<(3,0);assert version("cvss")=="3.6";print("NumPy "+numpy.__version__+"; CVSS "+version("cvss"))'
    $testeDeps = Testar-Comando $pythonVenv ('-I -c "' + $codigoDeps.Replace('"', '\"') + '"') 30000
    if ($testeDeps.Codigo -ne 0) {
        & $pythonVenv -I -m pip --isolated --disable-pip-version-check install --no-input --index-url https://pypi.org/simple --only-binary=:all: -r (Join-Path $aplicacao 'requirements.txt') | Out-Host
        if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel instalar as dependencias no ambiente isolado. Confira internet, proxy e a mensagem do pip acima.' }
        $testeDeps = Testar-Comando $pythonVenv ('-I -c "' + $codigoDeps.Replace('"', '\"') + '"') 30000
        if ($testeDeps.Codigo -ne 0) { throw "As dependencias nao passaram na verificacao: $($testeDeps.Saida)" }
    }
    Write-Host "  $($testeDeps.Saida)"
    Write-Progress -Activity 'Preparando Ciberseguranca T2' -Status 'Preparando dados ficticios e abertura animada' -PercentComplete 85
    if (-not (Test-Path -LiteralPath $dados)) { $null = New-Item -ItemType Directory -Path $dados }
    foreach ($par in @(@('dados_exemplo\inventario_exemplo.json', 'inventario.json'), @('base_cve\kev.json', 'base_cve.json'))) {
        $destino = Join-Path $dados $par[1]
        if (-not (Test-Path -LiteralPath $destino)) { Copy-Item -LiteralPath (Join-Path $aplicacao $par[0]) -Destination $destino }
    }
    $abertura = @(
        '"""Abertura animada do programa completo instalado no Windows ou Linux."""'
        ''
        'import importlib'
        'from multiprocessing import Event, Process'
        'import os'
        'from pathlib import Path'
        'import sys'
        'import time'
        ''
        ''
        'def preparar_ambiente(pasta):'
        '    """Isola os dados da demonstra\xe7\xe3o de configura\xe7\xf5es herdadas do computador."""'
        '    fontes = pasta / "aplicacao"'
        '    if not (fontes / "main.py").is_file():'
        '        raise FileNotFoundError('
        '            f"Programa ausente em {fontes}. Execute novamente o iniciador de preparacao.")'
        '    inventario = pasta / "dados_demo" / "inventario.json"'
        '    if not inventario.is_file():'
        '        raise FileNotFoundError('
        '            f"Invent\xe1rio de demonstra\xe7\xe3o ausente: {inventario}. "'
        '            "Execute novamente o iniciador de preparacao.")'
        '    sys.path.insert(0, str(fontes))'
        '    os.environ["INVENTARIO_DADOS"] = str(inventario)'
        '    os.environ["INVENTARIO_BASE_CVE"] = str(pasta / "dados_demo" / "base_cve.json")'
        '    os.environ.pop("INVENTARIO_EM_CONTAINER", None)'
        '    for fluxo in (sys.stdin, sys.stdout, sys.stderr):'
        '        if fluxo is not None and hasattr(fluxo, "reconfigure"):'
        '            fluxo.reconfigure(encoding="utf-8", errors="replace")'
        ''
        ''
        'def mostrar_abertura(pronto, cancelado, iniciada):'
        '    """Anima em processo separado enquanto o programa prepara o primeiro menu."""'
        '    try:'
        '        import tkinter as tk'
        '        from tkinter import ttk'
        '    except ImportError:'
        '        print("Abertura gr\xe1fica indispon\xedvel: instale o suporte Tcl/Tk do Python. "'
        '              "Continuando no terminal.")'
        '        return'
        ''
        '    try:'
        '        janela = tk.Tk()'
        '    except tk.TclError as erro:'
        '        print(f"Abertura gr\xe1fica indispon\xedvel ({erro}). Continuando no terminal.")'
        '        return'
        '    janela.title("Ciberseguran\xe7a T2")'
        '    janela.configure(bg="#111827")'
        '    janela.resizable(False, False)'
        '    largura, altura = 580, 252'
        '    x = (janela.winfo_screenwidth() - largura) // 2'
        '    y = (janela.winfo_screenheight() - altura) // 2'
        '    janela.geometry(f"{largura}x{altura}+{x}+{y}")'
        '    tk.Label(janela, text="CIBERSEGURAN\xc7A T2", bg="#111827", fg="#f8fafc",'
        '             font=("Segoe UI", 23, "bold")).pack(pady=(34, 10))'
        '    tk.Label(janela, text="Invent\xe1rio \xb7 Vulnerabilidades \xb7 An\xe1lise de risco",'
        '             bg="#111827", fg="#cbd5e1", font=("Segoe UI", 11)).pack()'
        '    tk.Label(janela, text="Carregando o programa\u2026", bg="#111827", fg="#6ee7b7",'
        '             font=("Segoe UI", 11)).pack(pady=(26, 12))'
        '    estilo = ttk.Style(janela)'
        '    estilo.theme_use("clam")'
        '    estilo.configure("Carga.Horizontal.TProgressbar", troughcolor="#273449",'
        '                     background="#34d399", bordercolor="#273449",'
        '                     lightcolor="#34d399", darkcolor="#34d399")'
        '    barra = ttk.Progressbar(janela, length=470, mode="indeterminate",'
        '                            style="Carga.Horizontal.TProgressbar")'
        '    barra.pack()'
        '    barra.start(35)'
        '    inicio = time.monotonic()'
        '    agendamento = None'
        '    fechada = False'
        ''
        '    def fechar():'
        '        nonlocal fechada'
        '        if fechada:'
        '            return'
        '        fechada = True'
        '        barra.stop()'
        '        if agendamento is not None:'
        '            janela.after_cancel(agendamento)'
        '        janela.destroy()'
        ''
        '    def cancelar():'
        '        cancelado.set()'
        '        fechar()'
        ''
        '    def conferir():'
        '        nonlocal agendamento'
        '        agendamento = None'
        '        if not pronto.is_set() or time.monotonic() - inicio < 3:'
        '            agendamento = janela.after(30, conferir)'
        '            return'
        '        fechar()'
        ''
        '    def ao_mostrar(evento):'
        '        nonlocal inicio'
        '        if evento.widget is janela and not iniciada.is_set():'
        '            janela.update_idletasks()'
        '            inicio = time.monotonic()'
        '            iniciada.set()'
        ''
        '    janela.bind("<Map>", ao_mostrar)'
        '    janela.protocol("WM_DELETE_WINDOW", cancelar)'
        '    agendamento = janela.after(30, conferir)'
        '    try:'
        '        janela.mainloop()'
        '    finally:'
        '        fechar()'
        ''
        ''
        'def carregar_com_abertura():'
        '    """Executa o programa na thread principal e fecha a abertura no primeiro menu."""'
        '    pronto, cancelado, iniciada = Event(), Event(), Event()'
        '    abertura = Process(target=mostrar_abertura, args=(pronto, cancelado, iniciada), daemon=True)'
        '    abertura.start()'
        '    exibir_menu_original = None'
        '    try:'
        '        while not iniciada.wait(0.05) and abertura.is_alive():'
        '            pass'
        '        if cancelado.is_set():'
        '            return'
        '        aplicacao = importlib.import_module("main")'
        '        if cancelado.is_set():'
        '            return'
        '        exibir_menu_original = aplicacao.Aplicacao.exibir_menu'
        ''
        '        def menu_pronto(self):'
        '            if cancelado.is_set():'
        '                raise SystemExit(0)'
        '            pronto.set()'
        '            abertura.join()'
        '            aplicacao.Aplicacao.exibir_menu = exibir_menu_original'
        '            if cancelado.is_set():'
        '                raise SystemExit(0)'
        '            exibir_menu_original(self)'
        '            sys.stdout.flush()'
        ''
        '        aplicacao.Aplicacao.exibir_menu = menu_pronto'
        '        aplicacao.main()'
        '    finally:'
        '        if exibir_menu_original is not None:'
        '            aplicacao.Aplicacao.exibir_menu = exibir_menu_original'
        '        pronto.set()'
        '        abertura.join()'
        ''
        ''
        'def main():'
        '    pasta = Path(__file__).resolve().parent'
        '    try:'
        '        preparar_ambiente(pasta)'
        '        carregar_com_abertura()'
        '        return 0'
        '    except SystemExit as erro:'
        '        codigo = erro.code if isinstance(erro.code, int) else 1'
        '        if erro.code and not isinstance(erro.code, int):'
        '            print(erro.code, file=sys.stderr)'
        '    except Exception as erro:'
        '        print(f"\nN\xe3o foi poss\xedvel iniciar Ciberseguran\xe7a T2: "'
        '              f"{type(erro).__name__}: {erro}", file=sys.stderr)'
        '        codigo = 1'
        '    if codigo and sys.stdin is not None and sys.stdin.isatty():'
        '        try:'
        '            input("\nPressione Enter para fechar\u2026 ")'
        '        except (EOFError, KeyboardInterrupt):'
        '            pass'
        '    return codigo'
        ''
        ''
        'if __name__ == "__main__":'
        '    raise SystemExit(main())'
    )
    [System.IO.File]::WriteAllLines((Join-Path $raiz 'ABERTURA_DEMO.py'), $abertura, (New-Object System.Text.UTF8Encoding $false))
    Write-Progress -Activity 'Preparando Ciberseguranca T2' -Status 'Pronto para abrir o programa completo' -PercentComplete 100
    Write-Progress -Activity 'Preparando Ciberseguranca T2' -Completed
    Write-Host '  Preparacao concluida. Abrindo animacao e menu do programa...' -ForegroundColor Green
    return $raiz
}

if ($MyInvocation.InvocationName -ne '.') {
    $transcricaoIniciada = $false
    try {
        try {
            $arquivoLog = Join-Path $env:TEMP 'Ciberseguranca_T2_preparacao.log'
            Start-Transcript -LiteralPath $arquivoLog -Append -ErrorAction Stop | Out-Null
            $transcricaoIniciada = $true
            Write-Host "Log de preparacao: $arquivoLog"
        } catch {
            Write-Warning "Nao foi possivel iniciar o log: $($_.Exception.Message)"
        }
        $buildWindows = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuildNumber -ErrorAction SilentlyContinue).CurrentBuildNumber
        Write-Host ('Diagnostico: Windows build {0}; PowerShell {1}; processo {2} bits.' -f $buildWindows, $PSVersionTable.PSVersion, ([IntPtr]::Size * 8))
        if ($PSVersionTable.PSVersion -lt [version]'5.1') { throw 'Este preparador precisa do Windows PowerShell 5.1 ou superior. Abra a versao atual do PowerShell e tente novamente.' }
        $pastaDemo = Preparar-Demo
        $executavelDemo = Join-Path $pastaDemo '.venv\Scripts\python.exe'
        $aberturaDemo = Join-Path $pastaDemo 'ABERTURA_DEMO.py'
        $processoDemo = Start-Process -FilePath $executavelDemo -ArgumentList ('-I -X utf8 "' + $aberturaDemo + '"') -WorkingDirectory $pastaDemo -WindowStyle Normal -Wait -PassThru
        if ($processoDemo.ExitCode -eq -1073741510) {
            Write-Host 'Demonstracao interrompida pelo console (Ctrl+C ou fechamento da janela).' -ForegroundColor Yellow
        } elseif ($processoDemo.ExitCode -ne 0) { throw "O programa terminou com erro (codigo $($processoDemo.ExitCode)). Os dados da demonstracao foram preservados." }
    } catch {
        Write-Progress -Activity 'Preparando Ciberseguranca T2' -Completed
        Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'A janela permanece aberta para voce ler a mensagem e repetir a preparacao.'
        throw
    } finally {
        if ($transcricaoIniciada) {
            try { Stop-Transcript -ErrorAction Stop | Out-Null }
            catch { Write-Warning "Nao foi possivel concluir o log: $($_.Exception.Message)" }
        }
    }
}
