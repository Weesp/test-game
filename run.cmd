@echo off
cd /d "%~dp0"
if exist "..\Godot_v4.7.2-stable_win64.exe" (
    start "" "..\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
    exit /b
)
where godot >nul 2>nul
if not errorlevel 1 (
    start "" godot --path "%~dp0."
    exit /b
)
echo Open project.godot with Godot 4.7.2 to play.
pause
