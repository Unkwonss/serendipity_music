@echo off
chcp 65001 >nul
title Serendipity Odyssey - Development Launcher

echo ========================================================
echo   🎵 SERENDIPITY ODYSSEY - DEVELOPMENT LAUNCHER
echo ========================================================
echo.

echo [1/2] Kiem tra Backend Python (Port 8000)...
netstat -ano | findstr LISTENING | findstr :8000 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [Backend] Dang khoi dong Backend tai http://127.0.0.1:8000...
    start "Serendipity-Backend" /min cmd /k "cd /d %~dp0serendipity_backend && python main.py"
    timeout /t 3 /nobreak >nul
    echo [Backend] Da bat Backend thanh cong!
) else (
    echo [Backend] Backend da san sang tai http://127.0.0.1:8000.
)
echo.

echo [2/2] Khoi chay Serendipity tren Android 15 (API 35)...
echo [Flutter] Nhan 'r' de Hot Reload, 'R' de Hot Restart, 'q' de thoat.
echo.

cd /d "%~dp0serendipity_music"
flutter run -d emulator-5554 --no-enable-impeller

echo.
echo ========================================================
echo   Ung dung da dong. Nhan phim bat ky de thoat.
echo ========================================================
pause >nul
