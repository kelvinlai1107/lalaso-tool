@echo off
cd /d "%~dp0"
git config user.email "kelvinlai1107@gmail.com"
git config user.name "Kelvin"

rem 清除殘留 lock 檔
if exist ".git\index.lock" (
    del /f ".git\index.lock"
    echo [已清除 index.lock]
)

git add index.html
git commit -m "更新 %date% %time:~0,5%"
git push origin main
echo.
echo 完成！GitHub Pages 約 1-2 分鐘後更新。
pause
