<#
.SYNOPSIS
    Exchange Asset Dependency Ghost Hunter Wrapper
    Wrapper to run the Python script for dependency analysis.

.DESCRIPTION
    This script is a wrapper for 'ghost_hunter.py'. It ensures Python is installed
    and passes all arguments to the Python script.

.EXAMPLE
    .\ghost_hunter.ps1 --username user ...
#>

$PythonScript = "$PSScriptRoot\ghost_hunter.py"

if (-not (Test-Path $PythonScript)) {
    Write-Host "❌ Error: 'ghost_hunter.py' not found in the current directory." -ForegroundColor Red
    exit 1
}

# Check for Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Found: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error: Python is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

Write-Host "👻 Launching Ghost Hunter..." -ForegroundColor Cyan

# Pass all arguments to the Python script
python $PythonScript @args
