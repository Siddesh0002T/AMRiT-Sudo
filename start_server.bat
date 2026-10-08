@echo off
title BlueMesh MySQL / phpMyAdmin API Server (Port 8000)
echo ========================================================
echo   Starting BlueMesh Institutional API on 0.0.0.0:8000
echo   Compatible with Laptop Mobile Hotspot & Local Wi-Fi
echo ========================================================
echo.
echo Checking IP Configuration...
ipconfig | findstr /i "IPv4"
echo.
echo Database: MySQL / phpMyAdmin (bluemesh_db)
echo Server listening on: http://0.0.0.0:8000
echo Connect phones to your Laptop Hotspot and set host IP in app!
echo.
"C:\xampp\php\php.exe" -S 0.0.0.0:8000 -t backend/
pause
