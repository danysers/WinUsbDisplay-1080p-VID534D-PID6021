@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Aplicar_Optimizacion_1080p.ps1"
endlocal
