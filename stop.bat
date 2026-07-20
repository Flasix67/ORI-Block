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

:: Иначе удаляем записи из списка
if not exist "%LIST%" (
    echo [!] list-general.txt не найден.
    pause & exit /b
)

set "TEMP=%HOSTS%.tmp"
copy "%HOSTS%" "%TEMP%" >nul 2>&1

for /f "usebackq eol=# delims=" %%a in ("%LIST%") do (
    set "D=%%a"
    for /f "tokens=*" %%b in ("!D!") do set "D=%%b"
    if defined D (
        findstr /v /i /c:"127.0.0.1 !D!" /c:"127.0.0.1 www.!D!" "%TEMP%" > "%TEMP%.2" 2>nul
        move /y "%TEMP%.2" "%TEMP%" >nul 2>&1
    )
)
move /y "%TEMP%" "%HOSTS%" >nul 2>&1
del /f /q "%TEMP%.2" "%TEMP%" >nul 2>&1

:FLUSH
ipconfig /flushdns >nul 2>&1
echo [+] ORI-Block disabled!
timeout /t 2 >nul
exit /b