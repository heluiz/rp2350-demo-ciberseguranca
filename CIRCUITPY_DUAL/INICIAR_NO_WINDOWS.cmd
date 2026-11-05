@echo off
setlocal DisableDelayedExpansion
set "CIBER_T2_PREPARADOR=%~dp0CIBER_T2\PREPARAR_DEMO.ps1"
if not exist "%CIBER_T2_PREPARADOR%" set "CIBER_T2_PREPARADOR=%~dp0PREPARAR_DEMO.ps1"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -Command "$ErrorActionPreference='Stop';$p=$env:CIBER_T2_PREPARADOR;if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne '6CDFD2948EFC68CD011FDFFB40687BC8F75C26FDF43F78755770A083E622937D'){throw 'Preparador USB diferente do esperado.'};@(Get-Content -LiteralPath $p -ErrorAction Stop;'') | & ($env:SystemRoot+'\System32\WindowsPowerShell\v1.0\powershell.exe') -NoLogo -NoProfile -STA -Command -;if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}"
set "CIBER_T2_CODIGO=%ERRORLEVEL%"
if not "%CIBER_T2_CODIGO%"=="0" (
    echo Falha na preparacao. Leia a mensagem acima.
    pause
)
exit /b %CIBER_T2_CODIGO%
