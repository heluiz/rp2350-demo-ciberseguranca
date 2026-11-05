@echo off
setlocal DisableDelayedExpansion
echo Escolha o sistema do computador em que a placa sera conectada:
echo 1 - Windows automatico
echo 2 - Linux manual: abrir o iniciador na unidade USB
echo 3 - Manual, sem digitar comandos automaticamente
choice /C 123 /N /M "Opcao: "
if errorlevel 4 exit /b 1
set "escolha=%errorlevel%"
cmd /D /C exit 0
if "%escolha%"=="3" goto manual
if "%escolha%"=="2" goto linux
if "%escolha%"=="1" goto windows
exit /b 1
:windows
>"%~dp0modo.txt" echo windows
goto pronto
:linux
>"%~dp0modo.txt" echo linux
goto pronto
:manual
>"%~dp0modo.txt" echo manual
:pronto
if errorlevel 1 (
    echo Nao foi possivel salvar modo.txt.
    pause
    exit /b 1
)
echo Modo salvo. Desconecte e conecte a placa no sistema escolhido.
pause
exit /b 0
