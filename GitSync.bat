@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
pushd %~dp0..\..\..
echo %cd%

REM === Настройки ===
set "BASE_CONFLICT_DIR=⛔️GitConflicts"
set "BRANCH="
set "LOGS=C:\CB_Env\game-docs\.trash\GitSync.log"

REM === Формируем папку по дате ===
for /f %%i in ('powershell -command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "DATETIME=%%i"
set "CONFLICT_DIR=%BASE_CONFLICT_DIR%\%DATETIME%"

echo [1/5] Committing local changes...
git add .
git commit -m "Auto sync commit" >nul 2>&1

echo [2/5] Pulling remote changes...
git pull origin %BRANCH% --no-rebase --no-edit > %LOGS% 2>&1

REM Проверка на конфликты
findstr /C:"CONFLICT (" %LOGS% >nul
if %errorlevel%==0 (
    echo ⚠️  Merge conflict detected. Processing...

    mkdir "%CONFLICT_DIR%" 2>nul

    for /f "tokens=*" %%f in ('git diff --name-only --diff-filter=U') do (
        set "FILE=%%f"
        set "SAFEFILE=%%f"
        set "SAFEFILE=!SAFEFILE:/=__!"

        git show :2:!FILE! > "!CONFLICT_DIR!\(LOCAL)!SAFEFILE!"
        git show :3:!FILE! > "!CONFLICT_DIR!\(REMOTE)!SAFEFILE!"

        REM Оставляем текущую (ours) версию как рабочую
        git checkout --ours "!FILE!"
        git add "!FILE!"
    )

    echo ✅ Conflicts copied to "!CONFLICT_DIR!". Using OURS version.
)

echo [3/5] Final commit (if needed)...
git commit -m "Resolve conflicts via ours" >nul 2>&1

echo [4/5] Pushing to remote...
git push origin %BRANCH%
