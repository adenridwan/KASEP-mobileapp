@echo off
echo ========================================
echo    KASEP - Build APK Script
echo ========================================
echo.

cd /d %~dp0

where flutter >nul 2>nul
if errorlevel 1 (
    if exist "C:\src\flutter\bin\flutter.bat" (
        set "PATH=C:\src\flutter\bin;%PATH%"
    ) else (
        echo ERROR: flutter not found. Add Flutter's bin folder to PATH.
        pause
        exit /b 1
    )
)

echo [1/3] Cleaning build cache...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Building Release APK...
call flutter build apk --release --android-skip-build-dependency-validation
set BUILD_RESULT=%errorlevel%

echo.
echo ========================================
if %BUILD_RESULT%==0 if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo BUILD SUCCESS!
    echo.
    echo APK Location:
    echo   %cd%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Copy APK to current folder...
    copy /y "build\app\outputs\flutter-apk\app-release.apk" "KASEP-release.apk"
    echo.
    echo Done! File: KASEP-release.apk
    goto end
)
echo BUILD FAILED!
echo Check the error messages above.

:end
echo ========================================
pause
