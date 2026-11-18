@echo off
title Build Windows Desktop Installer (.exe) - Syedpur Kuddusia Madrasa
cd /d "%~dp0"

echo ================================================================
echo   উইন্ডোজ ডেস্কটপ ইনস্টলার (.exe) বিল্ডার
echo   Saidpur kudduchiyya madrasah Membership System
echo ================================================================
echo.

where node >nul 2>nul
if %errorlevel% neq 0 (
  echo [ERROR] Node.js পাওয়া যায়নি! প্রথমে Node.js v20+ LTS ইনস্টল করুন।
  pause
  exit /b 1
)

if not exist "node_modules\" (
  echo [1/4] ডিপেনডেন্সি ইনস্টল করা হচ্ছে...
  call npm install
)

echo [2/4] Electron এবং Electron-Builder প্রস্তুত করা হচ্ছে...
call npm install --no-save electron electron-builder

echo [3/4] অ্যাপ্লিকেশন প্রোডাকশন বিল্ড হচ্ছে...
call npm run build
if %errorlevel% neq 0 (
  echo [ERROR] Vite build ব্যর্থ হয়েছে।
  pause
  exit /b 1
)

echo [4/4] Windows NSIS Installer ও Portable .exe তৈরি হচ্ছে (release-win\)...
call npx electron-builder --config electron/electron-builder.json --win
if %errorlevel% neq 0 (
  echo [ERROR] Windows installer তৈরি করতে সমস্যা হয়েছে।
  pause
  exit /b 1
)

echo.
echo [SUCCESS] release-win ফোল্ডারে Windows .exe ইনস্টলার সফলভাবে তৈরি হয়েছে!
explorer "%~dp0release-win"
pause
