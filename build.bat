@echo off
setlocal enabledelayedexpansion

set COUNTER_FILE=build_counter.txt

if not exist %COUNTER_FILE% (
    echo|set /p="1" > %COUNTER_FILE%
)

set /p BUILD_NUM=<%COUNTER_FILE%

for /f "tokens=* delims= " %%a in ("%BUILD_NUM%") do set BUILD_NUM=%%a
for /f "tokens=* delims= " %%a in ("%BUILD_NUM%") do set BUILD_NUM=%%a

echo.
echo ================================
echo  Build nr. %BUILD_NUM%
echo ================================
echo.

flutter build apk --release --build-number=%BUILD_NUM% --build-name=1.0.%BUILD_NUM%

if %ERRORLEVEL% == 0 (
    set /a NEXT_NUM=%BUILD_NUM% + 1
    echo|set /p="!NEXT_NUM!" > %COUNTER_FILE%
    echo.
    echo ================================
    echo  APK generat cu succes!
    echo  Versiune: 1.0.%BUILD_NUM% ^(build %BUILD_NUM%^)
    echo  Fisier: build\app\outputs\flutter-apk\app-release.apk
    echo ================================
) else (
    echo.
    echo  Build esuat - numarul nu a fost incrementat.
)

pause
