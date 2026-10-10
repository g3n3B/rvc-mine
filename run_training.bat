@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

set "REPO_NAME=RVC-mine"
set "RVC_ROOT=%~dp0%REPO_NAME%"
set "VENV_DIR=%RVC_ROOT%\venv"

cls
echo.
echo    +===============================================+
echo    ^|                                               ^|
echo    ^|   ████████╗██████╗  █████╗ ██╗███╗  ██╗     ^|
echo    ^|      ██╔══╝██╔══██╗██╔══██╗██║████╗ ██║     ^|
echo    ^|      ██║   ██████╔╝███████║██║██╔██╗██║     ^|
echo    ^|      ██║   ██╔══██╗██╔══██║██║██║╚████║     ^|
echo    ^|      ██║   ██║  ██║██║  ██║██║██║ ╚███║     ^|
echo    ^|      ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚══╝    ^|
echo    ^|                                               ^|
echo    ^|        sexy-voice  //  200 epochs             ^|
echo    ^|        CPU only    //  Black Fire Games        ^|
echo    ^|                                               ^|
echo    +===============================================+
echo.
timeout /t 2 /nobreak >nul

if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo    [ERROR] Environment not found. Run rvc_setup.bat first.
    pause & exit /b 1
)

call "%VENV_DIR%\Scripts\activate.bat"
set "PYTHONPATH=%RVC_ROOT%"

echo    Starting training run...
echo    Experiment : sexy-voice
echo    Epochs     : 200  (checkpoint every 5)
echo    Hardware   : CPU only
echo.

python "%RVC_ROOT%\train\train_main.py" ^
  -e sexy-voice ^
  -sr 48k ^
  -f0 1 ^
  -bs 4 ^
  -te 200 ^
  -se 5 ^
  -pg "%RVC_ROOT%\assets\pretrained_v2\f0G48k.pth" ^
  -pd "%RVC_ROOT%\assets\pretrained_v2\f0D48k.pth" ^
  -l 1 ^
  -c 0 ^
  -sw 1 ^
  -v v2

if !ERRORLEVEL! NEQ 0 (
    echo.
    echo    [ERROR] Training exited with an error. See output above.
) else (
    echo.
    echo    +===============================================+
    echo    ^|   Training complete.                          ^|
    echo    +===============================================+
)
echo.
pause
