#!/bin/bash
# Quick test runner for GetSpot data integrity tests (Linux/Mac)

set -e

echo "===================================="
echo "GetSpot Data Integrity Test Suite"
echo "===================================="
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Virtual environment not found. Creating..."
    python3 -m venv venv
    echo ""
fi

# Activate virtual environment
source venv/bin/activate

# Check if requirements are installed
if ! python -c "import pytest" 2>/dev/null; then
    echo "Installing requirements..."
    pip install -r requirements.txt
    echo ""
fi

# Check for service account key
if [ ! -f "serviceAccountKey.json" ] && [ ! -f ".env" ]; then
    echo "ERROR: Service account key not found!"
    echo ""
    echo "Please download from Firebase Console:"
    echo "  Project Settings > Service Accounts > Generate New Private Key"
    echo ""
    echo "Save as: serviceAccountKey.json"
    echo ""
    exit 1
fi

echo "Running tests..."
echo ""

# Run tests based on argument
case "$1" in
    quick)
        echo "[Quick Mode] Running fast tests only..."
        pytest -m "not slow" "${@:2}"
        ;;
    full)
        echo "[Full Mode] Running all tests including slow ones..."
        export RUN_SLOW_TESTS=true
        pytest "${@:2}"
        ;;
    report)
        echo "[Report Mode] Generating HTML report..."
        pytest --html=report.html --self-contained-html "${@:2}"
        if [ -f "report.html" ]; then
            echo ""
            echo "Report generated: report.html"
            # Try to open report (works on Mac)
            command -v open >/dev/null && open report.html
        fi
        ;;
    help|--help|-h)
        echo "Usage:"
        echo "  ./run_tests.sh           - Run default tests"
        echo "  ./run_tests.sh quick     - Run fast tests only"
        echo "  ./run_tests.sh full      - Run all tests including slow ones"
        echo "  ./run_tests.sh report    - Generate HTML report"
        echo ""
        exit 0
        ;;
    *)
        echo "Running default tests..."
        pytest "$@"
        ;;
esac

echo ""
echo "===================================="
echo "Tests complete!"
echo "===================================="
