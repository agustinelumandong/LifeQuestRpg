@echo off
REM LifeQuestRPG Migration Helper
REM Usage: migrate.bat [run|status|help]

if "%1"=="" (
    php migrate.php help
) else (
    php migrate.php %1
)

pause
