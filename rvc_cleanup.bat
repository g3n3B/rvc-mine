@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

set "REPO_NAME=RVC-mine"
set "SCRIPT_DIR=%~dp0"
set "RVC_ROOT=%SCRIPT_DIR%%REPO_NAME%"
set "VENV_DIR=%RVC_ROOT%\venv"
set "TOKEN_FILE=%SCRIPT_DIR%token.txt"

cls
echo.
echo    +===============================================+
echo    ^|                                               ^|
echo    ^|    ██████╗██╗     ███████╗ █████╗ ███╗ ██╗  ^|
echo    ^|   ██╔════╝██║     ██╔════╝██╔══██╗████╗██║  ^|
echo    ^|   ██║     ██║     █████╗  ███████║██╔████║  ^|
echo    ^|   ██║     ██║     ██╔══╝  ██╔══██║██║╚███║  ^|
echo    ^|   ╚██████╗███████╗███████╗██║  ██║██║ ╚██║  ^|
echo    ^|    ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝  ^|
echo    ^|                                               ^|
echo    ^|         Push results. Nuke everything.        ^|
echo    ^|              Black Fire Games                 ^|
echo    ^|                                               ^|
echo    +===============================================+
echo.
timeout /t 2 /nobreak >nul

:: ============================================================
::  READ TOKEN
:: ============================================================
if not exist "%TOKEN_FILE%" (
    echo    [ERROR] token.txt not found at %SCRIPT_DIR%
    echo    Create a file called token.txt next to this script
    echo    containing only your GitHub personal access token.
    pause & exit /b 1
)
set /p GH_TOKEN=<"%TOKEN_FILE%"
set "GIT_REMOTE=https://g3n3B:!GH_TOKEN!@github.com/g3n3B/rvc-mine.git"

:: ============================================================
::  SAFETY CHECK
:: ============================================================
if not exist "%RVC_ROOT%\.git" (
    echo    [ERROR] Repo not found at %RVC_ROOT%
    echo    Nothing to clean up.
    pause & exit /b 1
)

echo    WARNING: This will push all results to GitHub
echo    and then permanently delete the RVC-mine folder.
echo.
set /p CONFIRM="    Type YES to continue: "
if /i not "!CONFIRM!"=="YES" (
    echo    Aborted.
    pause & exit /b 0
)
echo.

:: ============================================================
::  STEP 1 — COMMIT RESULTS
:: ============================================================
echo    [ 1 / 3 ]  Committing results...
echo    -----------------------------------------------
cd /d "%RVC_ROOT%"

git remote set-url origin "%GIT_REMOTE%"
git add -A

git diff --cached --quiet
if !ERRORLEVEL! == 0 (
    echo    ^> No changes to commit — already up to date.
) else (
    for /f "tokens=1-3 delims=/ " %%A in ('date /t') do set "DATESTR=%%A-%%B-%%C"
    for /f "tokens=1-2 delims=: " %%A in ('time /t') do set "TIMESTR=%%A%%B"
    git commit -m "training results — !DATESTR! !TIMESTR!"
    echo    ^> Committed.
)
echo.

:: ============================================================
::  STEP 2 — PUSH
:: ============================================================
echo    [ 2 / 3 ]  Pushing to GitHub...
echo    -----------------------------------------------
git push origin main
if !ERRORLEVEL! NEQ 0 (
    echo.
    echo    [ERROR] Push failed. Results NOT pushed.
    echo    Do NOT proceed with cleanup until this is resolved.
    pause & exit /b 1
)
echo    ^> Push confirmed.
echo.

:: ============================================================
::  STEP 3 — NUKE
:: ============================================================
echo    [ 3 / 3 ]  Cleaning up...
echo    -----------------------------------------------
cd /d "%SCRIPT_DIR%"

call "%VENV_DIR%\Scripts\deactivate.bat" >nul 2>&1

echo    ^> Removing RVC-mine...
rmdir /s /q "%RVC_ROOT%"
if !ERRORLEVEL! NEQ 0 (
    echo    [WARN] Could not fully remove folder — some files may be locked.
    echo    Close any open terminals or editors and delete manually.
) else (
    echo    ^> Done. No trace left.
)
echo.

echo    +===============================================+
echo    ^|                                               ^|
echo    ^|   Results pushed. Machine is clean.           ^|
echo    ^|   Pull from GitHub when you're ready again.   ^|
echo    ^|                                               ^|
echo    +===============================================+
echo.
pause
