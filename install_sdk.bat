@echo off
set JAVA_HOME=c:\Users\Xiaolu\jdk17
set ANDROID_HOME=c:\Users\Xiaolu\Android
set PATH=%JAVA_HOME%\bin;%PATH%

echo Accepting licenses...
echo y | %ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=%ANDROID_HOME% --licenses

echo.
echo Installing SDK...
echo y | %ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=%ANDROID_HOME% platform-tools platforms;android-34 build-tools;34.0.0

echo.
echo Done!
pause
