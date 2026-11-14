@echo off
rem Run once: installs backend libraries into the project virtual environment
set PY=%~dp0.venv_mcp\Scripts\python.exe
if not exist "%PY%" (
  echo Virtual environment not found: %PY%
  pause
  exit /b 1
)
"%PY%" -m pip install -r "%~dp0backend\requirements.txt"
"%PY%" -m pip install -r "%~dp0backend\requirements-scrapers.txt"
echo.
echo Done. You can now use start.bat
pause
