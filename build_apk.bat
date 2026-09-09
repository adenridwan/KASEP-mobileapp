@echo off
echo ========================================
echo    KASEP - Build APK Script
echo ========================================
echo.

cd /d %~dp0

echo [1/3] Cleaning build cache...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Building Release APK...
call flutter build apk --release --android-skip-build-dependency-validation

echo.
echo ========================================
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo BUILD SUCCESS!
    echo.
    echo APK Location:
    echo   %cd%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Copy APK to current folder...
    copy "build\app\outputs\flutter-apk\app-release.apk" "KASEP-release.apk"
    echo.
    echo Done! File: KASEP-release.apk
) else (
    echo BUILD FAILED!
    echo Check the error messages above.
)
echo ========================================
pause
