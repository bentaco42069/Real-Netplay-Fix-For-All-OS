@echo off
REM ============================================================================
REM  Claude Remote-Control - Always On   (the "sister program" for your PC)
REM ----------------------------------------------------------------------------
REM  Fixes the real problem: your PC not reliably showing up in the phone app.
REM    * RE-ANNOUNCES on a timer so the PC keeps showing up  (REFRESH_MINUTES)
REM    * RECONNECTS if the link ever drops or crashes        (restart loop)
REM    * RESUMES the SAME session, not a new one             (--continue)
REM    * reaches ALL the projects you list                   (--add-dir)
REM  Pair with install-autostart.bat so it also starts at every login.
REM
REM  Real Claude Code flags (v2.1+):
REM    claude --remote-control [name] --continue --add-dir <dirs...>
REM ============================================================================
setlocal EnableDelayedExpansion

REM ==== SETTINGS -- edit these ================================================

REM  A stable name for this computer as it shows in the phone app:
set "SESSION_NAME=%COMPUTERNAME%"

REM  The MAIN project folder to resume in (your Ragnarok work, etc.):
set "PROJECT_DIR=%USERPROFILE%"

REM  ALL other project folders to reach in that one session. Blank, or e.g.:
REM    set "EXTRA_DIRS=--add-dir C:\Users\%USERNAME%\RagnarokOS C:\code\stuff"
set "EXTRA_DIRS="

REM  Keep the same session (--continue). Set to "" to always start fresh.
set "RESUME=--continue"

REM  Extra lever if your PC STILL doesn't show up while this window is running:
REM  re-announce every N minutes to force it back into the app's list. Leave at
REM  0 for the simple, rock-solid "always running" mode (fixes the most common
REM  cause). If it's confirmed running but still won't appear, set this to 15.
set "REFRESH_MINUTES=0"

REM ===========================================================================

if not "%~1"=="" set "PROJECT_DIR=%~1"

where claude >nul 2>nul
if errorlevel 1 (
  echo [!] The 'claude' command was not found. Install/update Claude Code first.
  if not "%CLAUDE_RC_NOPAUSE%"=="1" pause
  exit /b 1
)
cd /d "%PROJECT_DIR%" 2>nul
if errorlevel 1 (
  echo [!] Project folder not found: %PROJECT_DIR%   (edit PROJECT_DIR above)
  if not "%CLAUDE_RC_NOPAUSE%"=="1" pause
  exit /b 1
)

set /a REFRESH_MS=%REFRESH_MINUTES%*60000

set "MARKER=%~dp0.rc-initialized"
set "MODE=%RESUME%"
if not exist "%MARKER%" set "MODE="

echo ============================================================
echo   Claude Remote-Control - Always On
echo   Computer name : %SESSION_NAME%
echo   Project       : %CD%
echo   Re-announce   : every %REFRESH_MINUTES% min (0 = only on crash)
echo   Open the Claude app on your phone and pick this computer.
echo   (Close this window to stop.)
echo ============================================================

:loop
if "%REFRESH_MINUTES%"=="0" (
  claude --remote-control "%SESSION_NAME%" %MODE% %EXTRA_DIRS%
) else (
  REM  Run Remote Control but stop it after the refresh window, then loop
  REM  re-announces the PC so it reliably shows up in the app.
  powershell -NoProfile -Command "$a=@('--remote-control','%SESSION_NAME%'); if('%MODE%'.Trim()){$a+='--continue'}; $e='%EXTRA_DIRS%'.Trim(); if($e){$a+=($e -split ' +')}; $p=Start-Process claude -ArgumentList $a -PassThru -NoNewWindow; if(-not $p.WaitForExit(%REFRESH_MS%)){ try{$p.CloseMainWindow()|Out-Null; Start-Sleep 2; if(-not $p.HasExited){$p.Kill()}}catch{} }"
)
if not exist "%MARKER%" (echo initialized> "%MARKER%")
set "MODE=%RESUME%"
echo.
echo [*] Re-announcing to keep the PC visible in the app...
timeout /t 2 /nobreak >nul
goto :loop
