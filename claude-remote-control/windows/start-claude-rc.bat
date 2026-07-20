@echo off
REM ============================================================================
REM  Claude Remote-Control - Always On   (the "sister program" for your PC)
REM ----------------------------------------------------------------------------
REM  Keeps Claude's Remote Control running on THIS PC so the Claude app on your
REM  phone stays connected -- and it:
REM    * RECONNECTS itself if the link ever drops               (restart loop)
REM    * RESUMES the SAME session you were using, not a new one (--continue)
REM    * reaches ALL the projects you list, not just one folder (--add-dir)
REM  Pair with install-autostart.bat so it also starts at every login.
REM
REM  Uses the real Claude Code flags (v2.1+):
REM    claude --remote-control [name] --continue --add-dir <dirs...>
REM ============================================================================
setlocal

REM ==== SETTINGS -- edit these ================================================

REM  A stable name for this computer as it shows in the phone app:
set "SESSION_NAME=%COMPUTERNAME%"

REM  The MAIN project folder to resume in (your Ragnarok work, etc.).
REM  --continue reopens the most recent conversation in THIS folder, so keep it
REM  the same each time and you always land back where you left off.
set "PROJECT_DIR=%USERPROFILE%"

REM  ALL your other project folders you want reachable in that one session.
REM  Leave blank for none, or list them like:
REM    set "EXTRA_DIRS=--add-dir C:\Users\%USERNAME%\RagnarokOS C:\code\stuff"
set "EXTRA_DIRS="

REM  Session behavior:  --continue = keep the same session (what you asked for).
REM  Set to empty ("") if you ever want it to always start a fresh one instead.
set "RESUME=--continue"

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

REM  First run ever: no conversation exists yet, so start fresh (no --continue)
REM  and drop a marker. Every run after that resumes the SAME session.
set "MARKER=%~dp0.rc-initialized"
set "MODE=%RESUME%"
if not exist "%MARKER%" set "MODE="

echo ============================================================
echo   Claude Remote-Control - Always On
echo   Computer name : %SESSION_NAME%
echo   Project       : %CD%
echo   Session       : keep-same (--continue)   Extra dirs: %EXTRA_DIRS%
echo   Open the Claude app on your phone and pick this computer.
echo   (Close this window to stop.)
echo ============================================================

:loop
claude --remote-control "%SESSION_NAME%" %MODE% %EXTRA_DIRS%
if not exist "%MARKER%" (echo initialized> "%MARKER%")
set "MODE=%RESUME%"
echo.
echo [!] Remote Control stopped (code %errorlevel%). Reconnecting in 3s...
timeout /t 3 /nobreak >nul
goto :loop
