@echo off
:: Galaxy Buds3 Pro codec switch  --  SBC (game mode) ^<-^> AAC (quality mode)
:: Double-click to flip. Self-elevates. Buds drop and reconnect in ~5-10 s.

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\BthA2dp\Parameters" /v BluetoothAacEnable ^| find "BluetoothAacEnable"') do set cur=%%a

if "%cur%"=="0x0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\BthA2dp\Parameters" /v BluetoothAacEnable /t REG_DWORD /d 1 /f >nul
    set "mode=AAC  -  QUALITY MODE  - best sound for music and movies"
) else (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\BthA2dp\Parameters" /v BluetoothAacEnable /t REG_DWORD /d 0 /f >nul
    set "mode=SBC  -  GAME MODE  - lowest latency"
)

echo Restarting Bluetooth radio, buds will reconnect shortly...
pnputil /restart-device "USB\VID_0BDA&PID_4853\00E04C000001" >nul

echo.
echo  ====================================================================
echo   Now in:  %mode%
echo  ====================================================================
echo.
pause
