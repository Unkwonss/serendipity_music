@echo off
chcp 65001 >nul
echo ===================================================
echo   SERENDIPITY ODYSSEY - ONE-CLICK DEV LAUNCHER
echo ===================================================

echo [1/2] Kiem tra va khoi dong Backend Python...
powershell -Command "$c = Test-NetConnection -ComputerName 127.0.0.1 -Port 8000 -InformationLevel Quiet -WarningAction SilentlyContinue; if (!$c) { Start-Process cmd -ArgumentList '/k title Serendipity-Backend && cd /d %~dp0serendipity_backend && python main.py' -WindowStyle Minimized; Write-Host '>> Da khoi dong Backend tai 127.0.0.1:8000' } else { Write-Host '>> Backend dang chay san tai 127.0.0.1:8000' }"

echo [2/2] Khoi chay ung dung Flutter tren emulator-5554...
cd /d "%~dp0serendipity_music"
flutter run -d emulator-5554 --no-enable-impeller
