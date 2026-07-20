@echo off
REM Claude Phone Remote - host launcher (Windows). Double-click to run.
REM Auto-restarts the host if it ever crashes, so the remote comes back on its own.
setlocal
cd /d "%~dp0"

set "PY=python"
%PY% -c "import aiohttp, pyautogui" 1>nul 2>nul
if errorlevel 1 (
  echo [*] Installing host dependencies ^(one time^)...
  %PY% -m pip install -r requirements.txt
  if errorlevel 1 (
    echo [!] pip install failed. Install manually:  %PY% -m pip install -r requirements.txt
    pause
    exit /b 1
  )
)

echo [*] Starting Claude Phone Remote host ^(close this window to stop^).
:loop
%PY% claude_remote_host.py %*
if "%errorlevel%"=="0" goto :done
echo [!] Host exited ^(code %errorlevel%^). Restarting in 3s...
timeout /t 3 /nobreak >nul
goto :loop
:done
echo [*] Host stopped.
pause
