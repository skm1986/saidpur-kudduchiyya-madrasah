@echo off
title Syedpur Kuddusia Madrasa - Offline & Online Server
cd /d "%~dp0"

echo ================================================================
echo   সৈয়দপুর কুদ্দুসিয়া মাদ্রাসা — সদস্য ও চাঁদা ব্যবস্থাপনা সফটওয়্যার
echo   Saidpur kudduchiyya madrasah Membership Management System
echo ================================================================
echo.

where node >nul 2>nul
if %errorlevel% neq 0 (
  echo [ERROR] Node.js পাওয়া যায়নি! অনুগ্রহ করে https://nodejs.org থেকে Node.js LTS ^(v20+^) ইনস্টল করুন।
  echo [ERROR] Node.js not found. Please install Node.js v20+ LTS first.
  pause
  exit /b 1
)

if not exist ".env" (
  if exist ".env.example" (
    copy /Y ".env.example" ".env" >nul
    echo [INFO] .env কনফিগারেশন ফাইল তৈরি হয়েছে।
  )
)

if not exist "node_modules\" (
  echo [1/3] প্রথমবার সেটআপ হচ্ছে: প্রজেক্টের প্যাকেজ ইনস্টল করা হচ্ছে...
  call npm install
  if %errorlevel% neq 0 (
    echo [ERROR] npm install ব্যর্থ হয়েছে। ইন্টারনেট সংযোগ পরীক্ষা করুন।
    pause
    exit /b 1
  )
)

if not exist "dist\index.html" (
  echo [2/3] প্রোডাকশন বিল্ড তৈরি হচ্ছে...
  call npm run build
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $ws = New-Object -ComObject WScript.Shell; $lnk = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Syedpur Kuddusia Madrasa.lnk'); $lnk.TargetPath = '%~dp0setup-and-run-windows.bat'; $lnk.WorkingDirectory = '%~dp0'; $lnk.Description = 'Saidpur kudduchiyya madrasah Software'; $lnk.Save() } catch {}" >nul 2>nul

echo [3/3] সার্ভার চালু হচ্ছে (http://localhost:3000) — সম্পূর্ণ অফলাইন ও অনলাইন মোড প্রস্তুত...
if not exist "data\" mkdir "data"
set NODE_ENV=production
set PORT=3000
set SKM_ALLOW_OFFLINE_LOCAL_LOGIN=true

start "" cmd /c "timeout /t 3 /nobreak >nul && start http://localhost:3000"
call npx tsx server.ts
pause
