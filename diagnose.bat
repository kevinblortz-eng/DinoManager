@echo off
setlocal enabledelayedexpansion

echo [LOG] Starting Flutter Diagnostic
echo [LOG] Current Directory: %CD%
echo [LOG] Current Time: %date% %time%

cd /d c:\Users\kevin\Documents\DinoManager\flutter_app
echo [LOG] Changed to flutter_app directory

echo [LOG] Attempting flutter --version
C:\Users\kevin\Downloads\flutter_app_updated\flutter\bin\flutter.bat --version 2>&1
echo [LOG] Exit Code: %ERRORLEVEL%

echo [LOG] Attempting flutter doctor
C:\Users\kevin\Downloads\flutter_app_updated\flutter\bin\flutter.bat doctor 2>&1
echo [LOG] Exit Code: %ERRORLEVEL%

echo [LOG] Diagnostic complete
pause
