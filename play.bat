@echo off
title Lean Factory — Dev Mode
cd /d "%~dp0"
echo Starting Lean Factory (dev mode — errors shown here)
echo.
".venv\Scripts\python.exe" main.py
echo.
echo Game exited.
pause
