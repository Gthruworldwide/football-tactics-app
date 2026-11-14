@echo off
rem Starts the backend. Keep this window open while using the app.
set PY=%~dp0.venv_mcp\Scripts\python.exe
echo Your computer address (use it in the app, port 8000):
ipconfig | findstr /i "IPv4"
echo.
cd /d "%~dp0backend"
"%PY%" -m uvicorn app.main:app --host 0.0.0.0 --port 8000
pause
