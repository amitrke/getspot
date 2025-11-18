@echo off
REM Quick test runner for GetSpot data integrity tests (Windows)

echo ====================================
echo GetSpot Data Integrity Test Suite
echo ====================================
echo.

REM Check if virtual environment exists
if not exist "venv\" (
    echo Virtual environment not found. Creating...
    python -m venv venv
    echo.
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Check if requirements are installed
python -c "import pytest" 2>nul
if errorlevel 1 (
    echo Installing requirements...
    pip install -r requirements.txt
    echo.
)

REM Check for service account key
if not exist "serviceAccountKey.json" (
    if not exist ".env" (
        echo ERROR: Service account key not found!
        echo.
        echo Please download from Firebase Console:
        echo   Project Settings ^> Service Accounts ^> Generate New Private Key
        echo.
        echo Save as: serviceAccountKey.json
        echo.
        pause
        exit /b 1
    )
)

echo Running tests...
echo.

REM Run tests based on argument
if "%1"=="quick" (
    echo [Quick Mode] Running fast tests only...
    pytest -m "not slow" %2 %3 %4 %5
) else if "%1"=="full" (
    echo [Full Mode] Running all tests including slow ones...
    set RUN_SLOW_TESTS=true
    pytest %2 %3 %4 %5
) else if "%1"=="report" (
    echo [Report Mode] Generating HTML report...
    pytest --html=report.html --self-contained-html %2 %3 %4 %5
    if exist "report.html" (
        echo.
        echo Report generated: report.html
        start report.html
    )
) else (
    echo Usage:
    echo   run_tests.bat           - Run default tests
    echo   run_tests.bat quick     - Run fast tests only
    echo   run_tests.bat full      - Run all tests including slow ones
    echo   run_tests.bat report    - Generate HTML report
    echo.
    echo Running default tests...
    pytest %1 %2 %3 %4 %5
)

echo.
echo ====================================
echo Tests complete!
echo ====================================
pause
