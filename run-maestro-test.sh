#!/bin/bash

# This script loads environment variables from the .env file
# and then runs the Maestro test command.

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found in current directory"
    exit 1
fi

# Read the .env file, ignore comments, and export environment variables
while IFS='=' read -r key value; do
    # Skip empty lines and comments
    if [[ -n "$key" && ! "$key" =~ ^[[:space:]]*# ]]; then
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Export the variable
        export "$key"="$value"
        echo "Set $key=$value"
    fi
done < .env

echo "Environment variables loaded from .env file"
echo ""

# Run the Maestro test
echo "Running Maestro smoke test..."
maestro test ./.maestro/smoke_test.yaml

# Uncomment the line below to run debug test instead
#maestro test ./.maestro/debug_test.yaml

# Optional: Pause at the end to see the output
# read -p "Press Enter to exit..."