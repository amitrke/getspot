# This script loads environment variables from the .env file
# and then runs the Maestro test command.

# Read the .env file, ignore comments, and set environment variables
Get-Content .\.env | ForEach-Object {
  if ($_ -match "=" -and -not $_.StartsWith("#")) {
    $key, $value = $_.Split("=", 2)
    # Set the variable for the current process
    [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
  }
}

# Run the Maestro test
# The test will now have access to the environment variables
maestro test .\.maestro\smoke_test.yaml
#maestro test .\.maestro\debug_test.yaml
# Optional: Pause at the end to see the output if running in a new window
# Read-Host -Prompt "Press Enter to exit"
