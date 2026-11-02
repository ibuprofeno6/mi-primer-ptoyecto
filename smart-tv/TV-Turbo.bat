@echo off
rem Doble clic aquí para abrir TV Turbo en Windows 10 u 11.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tv-turbo.ps1"
if errorlevel 1 pause
