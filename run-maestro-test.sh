#!/bin/bash

# This script loads environment variables from the .env file
# and then runs the Maestro test command with device-specific configuration.
#
# Usage:
#   ./run-maestro-test.sh [device-id] [test-file]
#
# Examples:
#   ./run-maestro-test.sh android-phone
#   ./run-maestro-test.sh ipad-13 debug_test.yaml
#   ./run-maestro-test.sh android-tablet-10

set -e  # Exit on error

# Parse command line arguments
DEVICE_ID="${1:-default}"
TEST_FILE="${2:-smoke_test.yaml}"

# Device configuration mapping
declare -A DEVICE_CONFIGS

# Function to set device config
set_device_config() {
    case "$1" in
        "android-phone")
            PLATFORM="Android"
            WIDTH=393
            HEIGHT=851
            ;;
        "android-tablet-7")
            PLATFORM="Android"
            WIDTH=600
            HEIGHT=960
            ;;
        "android-tablet-10")
            PLATFORM="Android"
            WIDTH=800
            HEIGHT=1280
            ;;
        "iphone-65")
            PLATFORM="iOS"
            WIDTH=428
            HEIGHT=926
            ;;
        "ipad-13")
            PLATFORM="iOS"
            WIDTH=1024
            HEIGHT=1366
            ;;
        "default")
            PLATFORM=""
            WIDTH=0
            HEIGHT=0
            ;;
        *)
            echo "Error: Unknown device ID '$1'"
            echo ""
            echo "Available device IDs:"
            echo "  android-phone (Android 393x851)"
            echo "  android-tablet-7 (Android 600x960)"
            echo "  android-tablet-10 (Android 800x1280)"
            echo "  iphone-65 (iOS 428x926)"
            echo "  ipad-13 (iOS 1024x1366)"
            exit 1
            ;;
    esac
}

# Set device configuration
set_device_config "$DEVICE_ID"

# Check if .env file exists and load it
if [ -f ".env" ]; then
    # Read the .env file, ignore comments, and export environment variables
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        if [[ -n "$key" && ! "$key" =~ ^[[:space:]]*# ]]; then
            # Remove leading/trailing whitespace and quotes
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)

            # Export the variable
            export "$key"="$value"
        fi
    done < .env
    echo "Loaded environment variables from .env file"
else
    echo "Warning: .env file not found"
fi

# Set screenshot directory environment variable
SCREENSHOT_DIR="screenshots/$DEVICE_ID"
export MAESTRO_SCREENSHOT_DIR="$SCREENSHOT_DIR"

# Create screenshots directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"
echo "Screenshot directory: $SCREENSHOT_DIR"

# Check if test file exists
TEST_PATH="./.maestro/$TEST_FILE"
if [ ! -f "$TEST_PATH" ]; then
    echo "Error: Test file not found: $TEST_PATH"
    exit 1
fi

echo ""
echo "Running Maestro test:"
echo "  Device: $DEVICE_ID"
echo "  Test: $TEST_FILE"
echo "  Screenshots: $SCREENSHOT_DIR"
echo ""

# Build maestro command
# Note: Maestro automatically detects connected devices
# Device-specific configurations are mainly for documentation/screenshot organization
MAESTRO_CMD="maestro test $TEST_PATH"

# Run the Maestro test
# The device dimensions in device configs are for reference only
# Maestro will use the actual connected device/emulator
eval $MAESTRO_CMD
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Test completed successfully!"
    echo "Screenshots saved to: $SCREENSHOT_DIR"
else
    echo "Test failed with exit code: $EXIT_CODE"
fi

exit $EXIT_CODE

# Optional: Pause at the end to see the output
# read -p "Press Enter to exit..."