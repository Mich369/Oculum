@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "scripts\build_distribution_oculum.ps1" %*
pause
