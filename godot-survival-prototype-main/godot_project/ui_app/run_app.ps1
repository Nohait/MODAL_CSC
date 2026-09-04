Write-Host "[INFO] Starting launcher..." -ForegroundColor Cyan

# Paths relative to this script's location
$Root = Resolve-Path "$PSScriptRoot\.."
$VenvPath = "$Root\.venv"
$ActivateScript = "$VenvPath\Scripts\Activate.ps1"
$PythonExe = "$VenvPath\Scripts\python.exe"

# 1. Create venv if missing
if (-Not (Test-Path $VenvPath)) {
    Write-Host "[INFO] Creating .venv..." -ForegroundColor Cyan
    python -m venv $VenvPath
}

# 2. Ensure activation script exists
if (-Not (Test-Path $ActivateScript)) {
    Write-Host "[ERROR] Activate.ps1 missing in .venv\Scripts" -ForegroundColor Red
    exit 1
}

# 3. Activate venv
Write-Host "[INFO] Activating .venv..." -ForegroundColor Cyan
. $ActivateScript

# 4. Install dependencies
Write-Host "[INFO] Checking dependencies..." -ForegroundColor Cyan
pip install -q PyQt6 imageio pillow

# 5. Launch app
Write-Host "[INFO] Launching AI Asset Generator..." -ForegroundColor Green
& $PythonExe "$PSScriptRoot\main.py"
