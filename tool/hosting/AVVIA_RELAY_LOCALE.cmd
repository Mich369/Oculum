@echo off
cd /d "%~dp0\..\.."
echo Avvio relay Oculum su ws://localhost:8787
echo Per fermarlo chiudi questa finestra.
build\oculum_relay_server.exe --port 8787
