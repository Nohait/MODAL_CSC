# Godot Survival Prototype - Asset Generation Pipeline
# PowerShell script to run Blender and generate all game assets

param(
    [switch]$Generate,
    [switch]$Export,
    [switch]$All,
    [string]$BlenderPath = ""
)

$ErrorActionPreference = "Stop"

# Find Blender
function Find-Blender {
    # Common installation paths
    $paths = @(
        "C:\Program Files\Blender Foundation\Blender 4.0\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 4.1\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 3.6\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 3.5\blender.exe",
        "$env:LOCALAPPDATA\Blender Foundation\Blender 4.0\blender.exe",
        "$env:LOCALAPPDATA\Blender Foundation\Blender 4.1\blender.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try to find via PATH
    $blenderInPath = Get-Command blender -ErrorAction SilentlyContinue
    if ($blenderInPath) {
        return $blenderInPath.Source
    }
    
    return $null
}

# Script paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$GenerateScript = Join-Path $ScriptDir "generate_survival_assets.py"
$ExportScript = Join-Path $ScriptDir "export_to_godot.py"

# Header
Write-Host "=" -NoNewline; Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host "  GODOT SURVIVAL PROTOTYPE - Asset Generation Pipeline" -ForegroundColor Yellow
Write-Host "=" -NoNewline; Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host ""

# Find Blender executable
if ($BlenderPath -and (Test-Path $BlenderPath)) {
    $Blender = $BlenderPath
} else {
    $Blender = Find-Blender
}

if (-not $Blender) {
    Write-Host "ERROR: Blender not found!" -ForegroundColor Red
    Write-Host "Please install Blender or specify path with -BlenderPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can download Blender from: https://www.blender.org/download/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Blender found: $Blender" -ForegroundColor Green
Write-Host ""

# Default to All if no options specified
if (-not $Generate -and -not $Export -and -not $All) {
    $All = $true
}

# Generate assets
if ($Generate -or $All) {
    Write-Host "[1/2] Generating 3D Assets..." -ForegroundColor Yellow
    Write-Host "  Running: $GenerateScript" -ForegroundColor Gray
    Write-Host ""
    
    $startTime = Get-Date
    
    & $Blender --background --python $GenerateScript
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Asset generation failed!" -ForegroundColor Red
        exit 1
    }
    
    $duration = (Get-Date) - $startTime
    Write-Host ""
    Write-Host "  Generation completed in $($duration.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Green
    Write-Host ""
}

# Export assets
if ($Export -or $All) {
    Write-Host "[2/2] Exporting to Godot Format..." -ForegroundColor Yellow
    Write-Host "  Running: $ExportScript" -ForegroundColor Gray
    Write-Host ""
    
    $startTime = Get-Date
    
    # First run generation to have objects in memory, then export
    & $Blender --background --python $GenerateScript --python $ExportScript
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Export failed!" -ForegroundColor Red
        exit 1
    }
    
    $duration = (Get-Date) - $startTime
    Write-Host ""
    Write-Host "  Export completed in $($duration.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Green
    Write-Host ""
}

# Summary
Write-Host "=" -NoNewline; Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host "  PIPELINE COMPLETE" -ForegroundColor Green
Write-Host "=" -NoNewline; Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host ""
Write-Host "Assets are ready in: $ScriptDir\..\assets\models\" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open Godot project" -ForegroundColor White
Write-Host "  2. The .glb files will be auto-imported" -ForegroundColor White
Write-Host "  3. Use the manifest.json to load assets programmatically" -ForegroundColor White
Write-Host ""
