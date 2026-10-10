@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: ============================================================
::  RVC-mine Bootstrap — Black Fire Games
::  Self-contained setup for CPU-only training on any Windows
::  machine. Run once; re-running is safe (idempotent).
:: ============================================================

set "REPO_URL=https://github.com/g3n3b/RVC-mine.git"
set "REPO_NAME=RVC-mine"
set "SCRIPT_DIR=%~dp0"
set "RVC_ROOT=%SCRIPT_DIR%%REPO_NAME%"
set "VENV_DIR=%RVC_ROOT%\venv"
set "REQ_FILE=%RVC_ROOT%\requirments_cpu_py312.txt"
set "PY_INSTALLER=%TEMP%\python_installer.exe"
set "PY_URL=https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe"

:: ============================================================
::  ASCII BANNER
:: ============================================================
cls
echo.
echo    ^+^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^+
echo    ^|                                               ^|
echo    ^|        ██████╗ ██╗   ██╗ ██████╗             ^|
echo    ^|        ██╔══██╗██║   ██║██╔════╝             ^|
echo    ^|        ██████╔╝██║   ██║██║                  ^|
echo    ^|        ██╔══██╗╚██╗ ██╔╝██║                  ^|
echo    ^|        ██║  ██║ ╚████╔╝ ╚██████╗             ^|
echo    ^|        ╚═╝  ╚═╝  ╚═══╝   ╚═════╝             ^|
echo    ^|                                               ^|
echo    ^|         Voice Conversion Training Setup       ^|
echo    ^|              Black Fire Games                 ^|
echo    ^|                                               ^|
echo    ^+^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^+
echo.
echo    CPU-only  ^|  Windows 11  ^|  RVC v2
echo.
timeout /t 2 /nobreak >nul

:: ============================================================
::  STEP 1 — PYTHON
:: ============================================================
echo    [ 1 / 4 ]  Checking Python...
echo    -----------------------------------------------
set "PYTHON_BIN="

for %%C in (python3.12 python3 python) do (
    if not defined PYTHON_BIN (
        where %%C >nul 2>&1
        if !ERRORLEVEL! == 0 (
            for /f "tokens=2 delims= " %%V in ('%%C --version 2^>^&1') do set "VER_STR=%%V"
            for /f "tokens=1,2 delims=." %%A in ("!VER_STR!") do (
                if %%A GEQ 3 if %%B GEQ 12 (
                    set "PYTHON_BIN=%%C"
                    echo    ^> Found: %%C ^(!VER_STR!^)
                )
            )
        )
    )
)

if not defined PYTHON_BIN (
    echo    ^> Python 3.12+ not found. Downloading installer...
    echo    ^> This may take a minute.
    powershell -Command "& { (New-Object Net.WebClient).DownloadFile('%PY_URL%', '%PY_INSTALLER%') }"
    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo    [ERROR] Download failed. Check your internet connection.
        pause & exit /b 1
    )
    echo    ^> Installing Python 3.12 silently...
    "%PY_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
    if !ERRORLEVEL! NEQ 0 (
        echo    [ERROR] Python install failed.
        pause & exit /b 1
    )
    del "%PY_INSTALLER%" >nul 2>&1
    :: Refresh PATH so python is visible in this session
    for /f "tokens=*" %%P in ('powershell -Command "[System.Environment]::GetEnvironmentVariable(\"PATH\",\"User\")"') do set "PATH=%%P;%PATH%"
    set "PYTHON_BIN=python"
    echo    ^> Python 3.12 installed.
)
echo.

:: ============================================================
::  STEP 2 — REPO
:: ============================================================
echo    [ 2 / 4 ]  Checking repository...
echo    -----------------------------------------------

where git >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo    ^> Git not found. Downloading Git for Windows...
    set "GIT_INSTALLER=%TEMP%\git_installer.exe"
    powershell -Command "& { $r = Invoke-WebRequest 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing | ConvertFrom-Json; $url = ($r.assets | Where-Object { $_.name -like '*64-bit.exe' } | Select-Object -First 1).browser_download_url; (New-Object Net.WebClient).DownloadFile($url, '%GIT_INSTALLER%') }"
    echo    ^> Installing Git silently...
    "%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
    del "%GIT_INSTALLER%" >nul 2>&1
    :: Refresh PATH for git
    set "PATH=C:\Program Files\Git\cmd;%PATH%"
)

if exist "%RVC_ROOT%\.git" (
    echo    ^> Repo found. Pulling latest...
    cd /d "%RVC_ROOT%"
    git pull
) else (
    echo    ^> Cloning RVC-mine from GitHub...
    cd /d "%SCRIPT_DIR%"
    git clone "%REPO_URL%"
    if !ERRORLEVEL! NEQ 0 (
        echo    [ERROR] Clone failed. Check your internet connection.
        pause & exit /b 1
    )
)
echo.

:: ============================================================
::  STEP 3 — VENV + DEPENDENCIES
:: ============================================================
echo    [ 3 / 4 ]  Setting up environment...
echo    -----------------------------------------------

if exist "%VENV_DIR%\Scripts\activate.bat" (
    echo    ^> Virtual environment already exists. Skipping creation.
) else (
    echo    ^> Creating virtual environment...
    %PYTHON_BIN% -m venv "%VENV_DIR%"
    if !ERRORLEVEL! NEQ 0 (
        echo    [ERROR] Failed to create venv.
        pause & exit /b 1
    )
)

call "%VENV_DIR%\Scripts\activate.bat"

echo    ^> Installing PyTorch CPU build...
pip install torch==2.4.1+cpu torchaudio==2.4.1+cpu torchvision==0.19.1+cpu ^
    --extra-index-url https://download.pytorch.org/whl/cpu --quiet
echo    ^> Installing remaining dependencies...
pip install -r "%REQ_FILE%" --quiet
echo.

:: ============================================================
::  STEP 4 — SMOKE TESTS
:: ============================================================
echo    [ 4 / 4 ]  Running checks...
echo    -----------------------------------------------

python -c "import torch; print('    torch', torch.__version__, '... OK')"
if !ERRORLEVEL! NEQ 0 (
    echo    [ERROR] torch import failed.
    pause & exit /b 1
)

python -c "import torchaudio; print('    torchaudio', torchaudio.__version__, '... OK')"
python -c "import librosa; print('    librosa', librosa.__version__, '... OK')"
python -c "import faiss; print('    faiss ... OK')"
python -c "import soundfile; print('    soundfile ... OK')"

if not exist "%RVC_ROOT%\train\train_main.py" (
    echo    [ERROR] train_main.py not found — repo may be incomplete.
    pause & exit /b 1
)
echo    train_main.py ... OK

if not exist "%RVC_ROOT%\assets\pretrained_v2\f0G48k.pth" (
    echo    [WARN] Pretrained weights missing — training will fail.
) else (
    echo    pretrained weights ... OK
)
echo.

:: ============================================================
::  DONE
:: ============================================================
echo    +===============================================+
echo    ^|                                               ^|
echo    ^|   Setup complete. You're good to go.          ^|
echo    ^|   Run  run_training.bat  to start.            ^|
echo    ^|                                               ^|
echo    +===============================================+
echo.
pause
