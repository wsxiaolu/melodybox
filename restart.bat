@echo off
echo Killing old server...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080') do taskkill /F /PID %%a 2>nul
timeout /t 2 /nobreak >nul
echo Starting MelodyBox...
cd /d "C:\Users\Xiaolu\melody_box"
start "MelodyBox" cmd /c "python server.py && pause"
timeout /t 3 /nobreak >nul
start http://localhost:8080
echo Done!
