@echo off
rem Refreshes xG / standings / players data from Understat
set PY=%~dp0.venv_mcp\Scripts\python.exe
cd /d "%~dp0backend"
"%PY%" -m scripts.scrape_understat
echo.
echo Data update finished.
pause
