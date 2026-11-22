@echo off
setlocal
where py.exe >nul 2>&1
if not errorlevel 1 (
    py -3 "%~dp0abrir_sentinel.py"
) else (
    python "%~dp0abrir_sentinel.py"
)
set "RESULTADO=%ERRORLEVEL%"
if not "%RESULTADO%"=="0" (
    echo Se faltar Python, instale a versao 3.11 ou mais recente.
    pause
)
exit /b %RESULTADO%

