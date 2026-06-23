@echo off
set JAVA_HOME=c:\Users\Xiaolu\jdk17
set ANDROID_HOME=c:\Users\Xiaolu\Android
set PATH=%JAVA_HOME%\bin;%PATH%
echo JAVA_HOME=%JAVA_HOME%
echo java at: %JAVA_HOME%\bin\java.exe
dir %JAVA_HOME%\bin\java.exe
call %ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=%ANDROID_HOME% platform-tools platforms;android-34 build-tools;34.0.0
pause
