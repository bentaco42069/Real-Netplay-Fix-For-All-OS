@echo off
REM Turn OFF "always running". Removes the Startup shortcut.
REM (Does not stop a copy that's already running -- close its window or reboot.)
setlocal
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ClaudeRemoteControl.lnk"
if exist "%LNK%" (
  del "%LNK%"
  echo [OK] Auto-start removed. It will no longer launch at login.
) else (
  echo [*] Auto-start was not installed. Nothing to remove.
)
echo.
pause
