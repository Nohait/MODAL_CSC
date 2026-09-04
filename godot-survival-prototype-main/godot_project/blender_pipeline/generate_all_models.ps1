# ============================================================================
# GODOT SURVIVAL PROTOTYPE - 3D ASSET GENERATION PIPELINE
# ============================================================================
# This script generates all 3D game assets using Blender and exports them
# in GLTF/GLB format for use in Godot 4.
#
# Requirements:
#   - Blender 3.6+ installed (auto-detected or specify path)
#   - Python 3.x (Blender's bundled Python)
#
# Usage:
#   .\generate_all_models.ps1                  # Generate everything
#   .\generate_all_models.ps1 -Category "env"  # Generate only environment
#   .\generate_all_models.ps1 -Export          # Export only (skip generation)
# ============================================================================

param(
    [string]$BlenderPath = "",
    [string]$Category = "all",
    [switch]$Export,
    [switch]$Clean,
    [switch]$Help
)

# Script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputDir = Join-Path $ScriptDir "exports"
$GodotAssets = Join-Path (Split-Path -Parent $ScriptDir) "assets\models"

# Generation scripts
$GenerateScript = Join-Path $ScriptDir "generate_master_assets.py"
$ExportScript = Join-Path $ScriptDir "export_all_assets.py"

function Show-Help {
    Write-Host @"
============================================================================
GODOT SURVIVAL PROTOTYPE - 3D Asset Generation Pipeline
============================================================================

USAGE:
    .\generate_all_models.ps1 [options]

OPTIONS:
    -BlenderPath <path>   Specify Blender executable path
    -Category <name>      Generate specific category only
                          Options: all, env, props, chars, enemies, weapons, 
                                   buildings, vehicles
    -Export               Export only (skip generation)
    -Clean                Clean output directories before generating
    -Help                 Show this help message

EXAMPLES:
    .\generate_all_models.ps1
        Generate and export all assets

    .\generate_all_models.ps1 -Category enemies
        Generate only enemy assets

    .\generate_all_models.ps1 -Clean
        Clean and regenerate everything

REQUIREMENTS:
    - Blender 3.6 or later
    - ~500MB free disk space for generated assets

OUTPUT:
    - exports/           GLB files organized by category
    - assets/models/     Copied to Godot project
    - manifest.json      Asset database for ModelManager

"@
}

function Find-Blender {
    Write-Host "`n[SETUP] Finding Blender installation..." -ForegroundColor Cyan
    
    # Common Blender locations on Windows
    $searchPaths = @(
        "C:\Program Files\Blender Foundation\Blender*\blender.exe",
        "C:\Program Files (x86)\Blender Foundation\Blender*\blender.exe",
        "$env:PROGRAMFILES\Blender Foundation\Blender*\blender.exe",
        "$env:LOCALAPPDATA\Blender Foundation\Blender*\blender.exe",
        "D:\Program Files\Blender Foundation\Blender*\blender.exe",
        "$env:USERPROFILE\blender*\blender.exe"
    )
    
    foreach ($pattern in $searchPaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | 
                 Sort-Object -Property FullName -Descending |
                 Select-Object -First 1
        
        if ($found) {
            Write-Host "  Found: $($found.FullName)" -ForegroundColor Green
            return $found.FullName
        }
    }
    
    # Try PATH
    $pathBlender = Get-Command blender -ErrorAction SilentlyContinue
    if ($pathBlender) {
        Write-Host "  Found in PATH: $($pathBlender.Source)" -ForegroundColor Green
        return $pathBlender.Source
    }
    
    return $null
}

function Clean-Output {
    Write-Host "`n[CLEAN] Removing old generated files..." -ForegroundColor Yellow
    
    if (Test-Path $OutputDir) {
        Remove-Item -Path $OutputDir -Recurse -Force
        Write-Host "  Removed: $OutputDir" -ForegroundColor Gray
    }
    
    if (Test-Path $GodotAssets) {
        Remove-Item -Path $GodotAssets -Recurse -Force
        Write-Host "  Removed: $GodotAssets" -ForegroundColor Gray
    }
    
    Write-Host "  Clean complete" -ForegroundColor Green
}

function Run-Generation {
    param([string]$BlenderExe)
    
    Write-Host "`n[GENERATE] Creating 3D assets in Blender..." -ForegroundColor Cyan
    Write-Host "  This may take several minutes..." -ForegroundColor Gray
    
    $startTime = Get-Date
    
    # Run Blender in background mode with our generation script
    $process = Start-Process -FilePath $BlenderExe `
        -ArgumentList "--background", "--python", $GenerateScript `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput (Join-Path $ScriptDir "generate_log.txt")
    
    $elapsed = (Get-Date) - $startTime
    
    if ($process.ExitCode -eq 0) {
        Write-Host "  Generation complete! (${elapsed.TotalSeconds:F1}s)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Generation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        Write-Host "  Check generate_log.txt for details" -ForegroundColor Yellow
        return $false
    }
}

function Run-Export {
    param([string]$BlenderExe)
    
    Write-Host "`n[EXPORT] Exporting assets to GLTF/GLB..." -ForegroundColor Cyan
    
    $startTime = Get-Date
    
    # Run export after generation (load the .blend file if it exists, otherwise regenerate)
    $blendFile = Join-Path $ScriptDir "generated_assets.blend"
    
    if (Test-Path $blendFile) {
        # Load existing blend and export
        $process = Start-Process -FilePath $BlenderExe `
            -ArgumentList "--background", $blendFile, "--python", $ExportScript `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput (Join-Path $ScriptDir "export_log.txt")
    } else {
        # Generate and export in one go
        $combinedScript = @"
import sys
sys.path.insert(0, r'$ScriptDir')
exec(open(r'$GenerateScript').read())
exec(open(r'$ExportScript').read())
"@
        $tempScript = Join-Path $ScriptDir "_temp_combined.py"
        $combinedScript | Out-File -FilePath $tempScript -Encoding UTF8
        
        $process = Start-Process -FilePath $BlenderExe `
            -ArgumentList "--background", "--python", $tempScript `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput (Join-Path $ScriptDir "export_log.txt")
        
        Remove-Item $tempScript -ErrorAction SilentlyContinue
    }
    
    $elapsed = (Get-Date) - $startTime
    
    if ($process.ExitCode -eq 0) {
        Write-Host "  Export complete! (${elapsed.TotalSeconds:F1}s)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Export failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        Write-Host "  Check export_log.txt for details" -ForegroundColor Yellow
        return $false
    }
}

function Show-Summary {
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "PIPELINE COMPLETE" -ForegroundColor Green
    Write-Host "="*60 -ForegroundColor Cyan
    
    # Count exported files
    if (Test-Path $GodotAssets) {
        $glbFiles = Get-ChildItem -Path $GodotAssets -Filter "*.glb" -Recurse
        $categories = Get-ChildItem -Path $GodotAssets -Directory
        
        Write-Host "`nExported Assets:" -ForegroundColor White
        foreach ($cat in $categories) {
            $count = (Get-ChildItem -Path $cat.FullName -Filter "*.glb" -ErrorAction SilentlyContinue).Count
            Write-Host "  $($cat.Name): $count models" -ForegroundColor Gray
        }
        Write-Host "`nTotal: $($glbFiles.Count) GLB files" -ForegroundColor Green
    }
    
    # Manifest info
    $manifestPath = Join-Path $GodotAssets "manifest.json"
    if (Test-Path $manifestPath) {
        Write-Host "`nManifest: $manifestPath" -ForegroundColor Cyan
    }
    
    Write-Host "`nAssets ready for Godot at:" -ForegroundColor White
    Write-Host "  res://assets/models/" -ForegroundColor Green
}

# ============================================================================
# MAIN
# ============================================================================

if ($Help) {
    Show-Help
    exit 0
}

Write-Host @"

============================================================================
 _     _    ____ _____   ____    _ __   __  ____  _   _ ______     _____     ___    _ 
| |   / \  / ___|_   _| |  _ \  / \\ \ / / / ___|| | | |  _ \ \   / /_ _\ \   / / \  | |
| |  / _ \ \___ \ | |   | | | |/ _ \\ V /  \___ \| | | | |_) \ \ / / | | \ \ / / _ \ | |
| |_/ ___ \ ___) || |   | |_| / ___ \| |    ___) | |_| |  _ < \ V /  | |  \ V / ___ \| |___
|___/_/   \_\____/ |_|   |____/_/   \_\_|   |____/ \___/|_| \_\ \_/  |___|  \_/_/   \_\_____|
                                                                                            
             3D ASSET GENERATION PIPELINE
============================================================================
"@ -ForegroundColor Magenta

# Find Blender
if ($BlenderPath -and (Test-Path $BlenderPath)) {
    $blender = $BlenderPath
    Write-Host "[SETUP] Using specified Blender: $blender" -ForegroundColor Cyan
} else {
    $blender = Find-Blender
}

if (-not $blender) {
    Write-Host "`n[ERROR] Blender not found!" -ForegroundColor Red
    Write-Host "Please install Blender 3.6+ or specify path with -BlenderPath" -ForegroundColor Yellow
    Write-Host "Download: https://www.blender.org/download/" -ForegroundColor Cyan
    exit 1
}

# Test Blender
Write-Host "[SETUP] Verifying Blender..." -ForegroundColor Cyan
$versionOutput = & $blender --version 2>&1 | Select-Object -First 1
Write-Host "  $versionOutput" -ForegroundColor Gray

# Clean if requested
if ($Clean) {
    Clean-Output
}

# Run pipeline
$totalStart = Get-Date

if (-not $Export) {
    $genSuccess = Run-Generation -BlenderExe $blender
    if (-not $genSuccess) {
        Write-Host "`n[ERROR] Generation failed. Aborting." -ForegroundColor Red
        exit 1
    }
}

$exportSuccess = Run-Export -BlenderExe $blender
if (-not $exportSuccess) {
    Write-Host "`n[ERROR] Export failed." -ForegroundColor Red
    exit 1
}

$totalElapsed = (Get-Date) - $totalStart
Write-Host "`nTotal time: $($totalElapsed.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Cyan

Show-Summary

Write-Host "`n[NEXT STEPS]" -ForegroundColor Yellow
Write-Host "1. Open Godot project" -ForegroundColor White
Write-Host "2. Assets will auto-import from assets/models/" -ForegroundColor White
Write-Host "3. Use ModelManager autoload to load models in code" -ForegroundColor White
Write-Host "`nExample: var tree = ModelManager.create_mesh_instance('tree_oak_00')" -ForegroundColor Gray
