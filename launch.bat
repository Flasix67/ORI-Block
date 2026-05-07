@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

set "HOSTS=%WINDIR%\System32\drivers\etc\hosts"
set "LIST=%~dp0list-general.txt"

if not exist "%LIST%" (
    echo [!] list-general.txt not found
    pause & exit /b
)

set "COUNT=0"
for /f "usebackq eol=# delims=" %%a in ("%LIST%") do (
    set "D=%%a"
    for /f "tokens=*" %%b in ("!D!") do set "D=%%b"
    if defined D (
        findstr /L /C:"127.0.0.1 !D!" "%HOSTS%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo 127.0.0.1 !D!>>"%HOSTS%"
            ::echo 127.0.0.1 www.!D!>>"%HOSTS%"
            set /a COUNT+=1
        )
    )
)

ipconfig /flushdns >nul 2>&1

echo Danger domains is blocked now.
echo [+] Blocked domains: !COUNT!
timeout /t 2 >nul
exit /b