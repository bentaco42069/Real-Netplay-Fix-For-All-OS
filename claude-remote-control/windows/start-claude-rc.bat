@echo off
REM ============================================================================
REM  Claude Remote-Control - Always On   (the "sister program")
REM ----------------------------------------------------------------------------
REM  Keeps `claude remote-control` running on THIS PC so the Claude app on your
REM  phone can always connect to it. If it ever drops or crashes, this relaunches
REM  it on its own -- so you stay connected without touching the terminal.
REM
REM  First time: just double-click this file, finish any login/pairing, then
REM  open the Claude phone app and pick this computer from the list.
REM  To make it start automatically at login, run install-autostart.bat.
REM ============================================================================
setlocal EnableDelayedExpansion

REM ---- EDIT THIS: the project folder you want Claude to work in --------------
REM  (the screenshot says "open the project you want Claude to work in")
set "PROJECT_DIR=%USERPROFILE%"
REM  Example for your Ragnarok work:
REM  set "PROJECT_DIR=C:\Users\%USERNAME%\RagnarokOS"

REM  You can also pass the folder as an argument: start-claude-rc.bat "C:\path"
if not "%~1"=="" set "PROJECT_DIR=%~1"

REM ---- Make sure Claude Code is installed ------------------------------------
where claude >nul 2>nul
if errorlevel 1 (
  echo [!] The 'claude' command was not found on your PATH.
  echo     Install or update Claude Code first, then run this again.
  echo     ^(In the phone app that screen is what appears once it can connect.^)
  if not "%CLAUDE_RC_NOPAUSE%"=="1" pause
  exit /b 1
)

REM ---- Move into the project folder ------------------------------------------
cd /d "%PROJECT_DIR%" 2>nul
if errorlevel 1 (
  echo [!] Project folder not found: %PROJECT_DIR%
  echo     Edit PROJECT_DIR near the top of this file, or pass a path as an argument.
  if not "%CLAUDE_RC_NOPAUSE%"=="1" pause
  exit /b 1
)

echo ============================================================
echo   Claude Remote-Control - Always On
echo   Project: %CD%
echo   Keeping 'claude remote-control' alive.
echo   Open the Claude app on your phone and pick this computer.
echo   (Close this window to stop.)
echo ============================================================

:loop
claude remote-control
echo.
echo [!] remote-control stopped (code %errorlevel%). Reconnecting in 3s...
timeout /t 3 /nobreak >nul
goto :loop
