@echo off
set JAVA_HOME=c:\Users\Xiaolu\jdk17
set ANDROID_HOME=c:\Users\Xiaolu\Android
set PATH=%JAVA_HOME%\bin;%PATH%

echo ==========================================
echo   MelodyBox Android 环境安装
echo ==========================================
echo.
echo 1. 接受许可协议（一路选 y）
echo ==========================================
call %ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=%ANDROID_HOME% --licenses

echo.
echo 2. 安装 SDK 组件
echo ==========================================
call %ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=%ANDROID_HOME% platform-tools platforms;android-34 build-tools;34.0.0

echo.
echo ==========================================
echo 3. 配置 Flutter
echo ==========================================
flutter config --android-sdk %ANDROID_HOME%
flutter doctor --android-licenses

echo.
echo ==========================================
echo 4. 编译 APK
echo ==========================================
cd /d C:\Users\Xiaolu\melodybox_android
flutter build apk --release

echo.
echo ==========================================
echo APK 位置: C:\Users\Xiaolu\melodybox_android\build\app\outputs\flutter-apk\app-release.apk
echo ==========================================
pause
