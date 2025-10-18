# This script loads environment variables from the .env file
# and then runs the Maestro test command with device-specific configuration.
#
# Usage:
#   .\run-maestro-test.ps1 [device-id] [test-file]
#
# Examples:
#   .\run-maestro-test.ps1 android-phone
#   .\run-maestro-test.ps1 ipad-13 debug_test.yaml
#   .\run-maestro-test.ps1 android-tablet-10

param(
    [Parameter(Position=0)]
    [string]$DeviceId = "default",

    [Parameter(Position=1)]
    [string]$TestFile = "smoke_test.yaml"
)

# Device configuration mapping
$deviceConfigs = @{
    "android-phone" = @{
        "platform" = "Android"
        "width" = 393
        "height" = 851
    }
    "android-tablet-7" = @{
        "platform" = "Android"
        "width" = 600
        "height" = 960
    }
    "android-tablet-10" = @{
        "platform" = "Android"
        "width" = 800
        "height" = 1280
    }
    "iphone-65" = @{
        "platform" = "iOS"
        "width" = 428
        "height" = 926
    }
    "ipad-13" = @{
        "platform" = "iOS"
        "width" = 1024
        "height" = 1366
    }
    "default" = @{
        "platform" = ""
        "width" = 0
        "height" = 0
    }
}

# Validate device ID
if (-not $deviceConfigs.ContainsKey($DeviceId)) {
    Write-Host "Error: Unknown device ID '$DeviceId'" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available device IDs:" -ForegroundColor Yellow
    $deviceConfigs.Keys | Sort-Object | ForEach-Object {
        if ($_ -ne "default") {
            $config = $deviceConfigs[$_]
            Write-Host "  $_ ($($config.platform) $($config.width)x$($config.height))"
        }
    }
    exit 1
}

# Read the .env file, ignore comments, and set environment variables
if (Test-Path .\.env) {
    Get-Content .\.env | ForEach-Object {
        if ($_ -match "=" -and -not $_.StartsWith("#")) {
            $key, $value = $_.Split("=", 2)
            # Set the variable for the current process
            [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
    Write-Host "Loaded environment variables from .env file" -ForegroundColor Green
} else {
    Write-Host "Warning: .env file not found" -ForegroundColor Yellow
}

# Set screenshot directory environment variable
$screenshotDir = "screenshots/$DeviceId"
[System.Environment]::SetEnvironmentVariable("MAESTRO_SCREENSHOT_DIR", $screenshotDir, "Process")

# Create screenshots directory if it doesn't exist
$fullScreenshotPath = ".\$screenshotDir"
if (-not (Test-Path $fullScreenshotPath)) {
    New-Item -ItemType Directory -Path $fullScreenshotPath -Force | Out-Null
    Write-Host "Created screenshot directory: $screenshotDir" -ForegroundColor Green
}

# Build maestro command
$testPath = ".\.maestro\$TestFile"
if (-not (Test-Path $testPath)) {
    Write-Host "Error: Test file not found: $testPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Running Maestro test:" -ForegroundColor Cyan
Write-Host "  Device: $DeviceId" -ForegroundColor Cyan
Write-Host "  Test: $TestFile" -ForegroundColor Cyan
Write-Host "  Screenshots: $screenshotDir" -ForegroundColor Cyan
Write-Host ""

# Build maestro command with device config
$maestroArgs = @("test", $testPath)

$config = $deviceConfigs[$DeviceId]
if ($config.platform -ne "") {
    $maestroArgs += "--platform"
    $maestroArgs += $config.platform
}
if ($config.width -gt 0 -and $config.height -gt 0) {
    $maestroArgs += "--device-width"
    $maestroArgs += $config.width
    $maestroArgs += "--device-height"
    $maestroArgs += $config.height
}

# Run the Maestro test
& maestro $maestroArgs

$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "Test completed successfully!" -ForegroundColor Green
    Write-Host "Screenshots saved to: $screenshotDir" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Test failed with exit code: $exitCode" -ForegroundColor Red
}

exit $exitCode

# Optional: Pause at the end to see the output if running in a new window
# Read-Host -Prompt "Press Enter to exit"
