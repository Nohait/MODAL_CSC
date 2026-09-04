@echo off
REM ============================================================================
REM GODOT SURVIVAL PROTOTYPE - 3D ASSET GENERATION PIPELINE (Windows Batch)
REM ============================================================================
REM Run this to generate all 3D game assets using Blender
REM ============================================================================

setlocal EnableDelayedExpansion

echo.
echo ============================================================================
echo        GODOT SURVIVAL PROTOTYPE - 3D ASSET GENERATION PIPELINE
echo ============================================================================
echo.

REM Find Blender
set "BLENDER="

REM Check common locations
for %%V in (4.2 4.1 4.0 3.6 3.5) do (
    if exist "C:\Program Files\Blender Foundation\Blender %%V\blender.exe" (
        set "BLENDER=C:\Program Files\Blender Foundation\Blender %%V\blender.exe"
        goto :found
    )
)

REM Check if in PATH
where blender >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%i in ('where blender') do set "BLENDER=%%i"
    goto :found
)

echo [ERROR] Blender not found!
echo Please install Blender 3.6+ from https://www.blender.org/download/
echo Or add Blender to your PATH
pause
exit /b 1

:found
echo [OK] Found Blender: %BLENDER%
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "GENERATE_SCRIPT=%SCRIPT_DIR%generate_master_assets.py"
set "EXPORT_SCRIPT=%SCRIPT_DIR%export_all_assets.py"

REM Create combined script for single Blender run
set "COMBINED_SCRIPT=%SCRIPT_DIR%_run_pipeline.py"
echo import sys > "%COMBINED_SCRIPT%"
echo sys.path.insert(0, r'%SCRIPT_DIR%') >> "%COMBINED_SCRIPT%"
echo exec(open(r'%GENERATE_SCRIPT%').read()) >> "%COMBINED_SCRIPT%"
echo exec(open(r'%EXPORT_SCRIPT%').read()) >> "%COMBINED_SCRIPT%"

echo [1/2] Generating 3D assets in Blender...
echo       This may take several minutes...
echo.

"%BLENDER%" --background --python "%COMBINED_SCRIPT%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Asset generation failed!
    del "%COMBINED_SCRIPT%" 2>nul
    pause
    exit /b 1
)

del "%COMBINED_SCRIPT%" 2>nul

echo.
echo ============================================================================
echo                         GENERATION COMPLETE!
echo ============================================================================
echo.
echo Assets exported to:
echo   - blender_pipeline\exports\    (GLB files)
echo   - assets\models\               (Godot-ready)
echo.
echo Next steps:
echo   1. Open Godot project
echo   2. Assets will auto-import
echo   3. Use ModelManager.get_model("asset_name") in code
echo.
pause
