@echo off
REM ============================================================================
REM  Turn ON "always running" so remote-control launches every time you log in.
REM  Puts a hidden-launch shortcut in your Startup folder. After this, your phone
REM  can connect whenever the PC is on -- you never start the terminal by hand.
REM
REM  Do the FIRST-time login/pairing by running start-claude-rc.bat once (visible)
REM  BEFORE enabling this, so any sign-in prompt isn't hidden.
REM ============================================================================
setlocal
cd /d "%~dp0"

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LNK=%STARTUP%\ClaudeRemoteControl.lnk"
set "TARGET=%~dp0run-hidden.vbs"

powershell -NoProfile -Command ^
  "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LNK%');" ^
  "$s.TargetPath='wscript.exe';" ^
  "$s.Arguments='\"%TARGET%\"';" ^
  "$s.WorkingDirectory='%~dp0';" ^
  "$s.WindowStyle=7;" ^
  "$s.Description='Claude Remote-Control (always on)';" ^
  "$s.Save()"

if exist "%LNK%" (
  echo.
  echo [OK] Auto-start is ON. remote-control will run hidden at every login.
  echo      Starting it now too, so you don't have to log out first...
  start "" wscript.exe "%TARGET%"
) else (
  echo [!] Could not create the Startup shortcut. Try running as your normal user.
)
echo.
pause
