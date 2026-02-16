# FM26 Accessibility Plugin Build Script
# Downloads dependencies and builds the plugin

param(
    [string]$Configuration = "Release",
    [string]$OutputPath = "",
    [switch]$SkipDownload = $false,
    [string]$FM26Path = ""
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  FM26 Accessibility Plugin Build Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check for .NET SDK
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
try {
    $dotnetVersion = & dotnet --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet command failed"
    }
    Write-Host "  .NET SDK: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "ERROR: .NET SDK is not installed or not on PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "The .NET SDK is required to build the FM26 Accessibility Plugin." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install it from:" -ForegroundColor Cyan
    Write-Host "  https://dotnet.microsoft.com/download" -ForegroundColor White
    Write-Host ""
    Write-Host "After installation, restart PowerShell and try again." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$libDir = Join-Path $rootDir "lib"
$srcDir = Join-Path $rootDir "src\FM26AccessibilityPlugin"

# BepInEx configuration
$bepInExVersion = "5.4.23.2"
$bepInExUrl = "https://github.com/BepInEx/BepInEx/releases/download/v$bepInExVersion/BepInEx_win_x64_$bepInExVersion.zip"

# Function to download and extract BepInEx
function Get-BepInExLibraries {
    Write-Host "Downloading BepInEx libraries..." -ForegroundColor Yellow
    
    $tempDir = Join-Path $env:TEMP "FM26Build_Temp"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    $zipPath = Join-Path $tempDir "BepInEx.zip"
    
    try {
        Write-Host "Downloading from: $bepInExUrl"
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($bepInExUrl, $zipPath)
        Write-Host "Download complete!" -ForegroundColor Green
        
        # Extract
        Write-Host "Extracting BepInEx..."
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)
        
        # Copy required DLLs
        Write-Host "Copying libraries to lib folder..."
        Copy-Item -Path (Join-Path $tempDir "BepInEx\core\BepInEx.dll") -Destination $libDir -Force
        Copy-Item -Path (Join-Path $tempDir "BepInEx\core\0Harmony.dll") -Destination $libDir -Force
        
        Write-Host "BepInEx libraries obtained successfully!" -ForegroundColor Green
        
        # Clean up
        Remove-Item $tempDir -Recurse -Force
        return $true
    } catch {
        Write-Host "Failed to download BepInEx: $_" -ForegroundColor Red
        return $false
    }
}

# Function to get Unity libraries from FM26
function Get-UnityLibraries {
    param([string]$ProvidedFM26Path = "")
    
    Write-Host ""
    Write-Host "Searching for Unity libraries from FM26 installation..." -ForegroundColor Yellow
    
    $fm26Path = $null
    
    # If FM26Path was provided as parameter, use it first
    if (-not [string]::IsNullOrEmpty($ProvidedFM26Path)) {
        Write-Host "Using provided FM26 path: $ProvidedFM26Path" -ForegroundColor Green
        if (Test-Path $ProvidedFM26Path) {
            $managedPath = Join-Path $ProvidedFM26Path "fm_Data\Managed"
            if (Test-Path $managedPath) {
                $fm26Path = $managedPath
            }
        }
    }
    
    # If not found or not provided, try to auto-detect
    if (-not $fm26Path) {
        # Try to find FM26
        $fm26Paths = @(
            "C:\Program Files (x86)\Steam\steamapps\common\Football Manager 2026",
            "C:\Program Files\Steam\steamapps\common\Football Manager 2026",
            "D:\Steam\steamapps\common\Football Manager 2026"
        )
        
        # Check registry for Steam
        try {
            $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue).SteamPath
            if ($steamPath) {
                $steamPath = $steamPath.Replace('/', '\')
                $fm26Paths += "$steamPath\steamapps\common\Football Manager 2026"
            }
        } catch {}
        
        foreach ($path in $fm26Paths) {
            if (Test-Path $path) {
                $managedPath = Join-Path $path "fm_Data\Managed"
                if (Test-Path $managedPath) {
                    $fm26Path = $managedPath
                    break
                }
            }
        }
    }
    
    if ($fm26Path) {
        Write-Host "Found FM26 at: $fm26Path" -ForegroundColor Green
        
        $requiredDlls = @(
            "UnityEngine.dll",
            "UnityEngine.CoreModule.dll",
            "UnityEngine.UI.dll",
            "UnityEngine.TextRenderingModule.dll"
        )
        
        $allFound = $true
        foreach ($dll in $requiredDlls) {
            $sourcePath = Join-Path $fm26Path $dll
            if (Test-Path $sourcePath) {
                Copy-Item -Path $sourcePath -Destination $libDir -Force
                Write-Host "  Copied: $dll" -ForegroundColor Green
            } else {
                Write-Host "  Missing: $dll" -ForegroundColor Red
                $allFound = $false
            }
        }
        
        return $allFound
    } else {
        Write-Host "Could not find FM26 installation." -ForegroundColor Yellow
        Write-Host "Unity DLLs must be provided manually to lib folder." -ForegroundColor Yellow
        return $false
    }
}

# Function to create stub DLLs if real ones aren't available
function Create-StubReferences {
    Write-Host ""
    Write-Host "Creating stub reference assemblies..." -ForegroundColor Yellow
    Write-Host "Note: These stubs allow building but won't work at runtime." -ForegroundColor Yellow
    Write-Host "For a working plugin, use real libraries from BepInEx and FM26." -ForegroundColor Yellow
    
    # This is a simplified approach - we'll just document that stubs are needed
    # In a real scenario, we'd create minimal assemblies with publicized types
    return $false
}

# Main build process
function Build-Plugin {
    Write-Host ""
    Write-Host "Building FM26 Accessibility Plugin..." -ForegroundColor Cyan
    
    try {
        Push-Location $rootDir
        
        # Restore dependencies
        Write-Host "Restoring dependencies..."
        dotnet restore $srcDir\FM26AccessibilityPlugin.csproj
        
        # Build
        Write-Host "Building in $Configuration configuration..."
        dotnet build $srcDir\FM26AccessibilityPlugin.csproj --configuration $Configuration --no-restore
        
        $builtDll = Join-Path $srcDir "bin\$Configuration\net48\FM26AccessibilityPlugin.dll"
        
        if (Test-Path $builtDll) {
            Write-Host ""
            Write-Host "Build successful!" -ForegroundColor Green
            Write-Host "Output: $builtDll" -ForegroundColor Green
            
            # Copy to build directory (for installer to find)
            $buildDir = Join-Path $rootDir "build"
            if (-not (Test-Path $buildDir)) {
                New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
            }
            Copy-Item -Path $builtDll -Destination $buildDir -Force
            Write-Host "Copied to: $buildDir\FM26AccessibilityPlugin.dll" -ForegroundColor Green
            
            # Copy to custom output path if specified
            if (-not [string]::IsNullOrEmpty($OutputPath)) {
                Copy-Item -Path $builtDll -Destination $OutputPath -Force
                Write-Host "Copied to: $OutputPath" -ForegroundColor Green
            }
            
            return $true
        } else {
            Write-Host "Build failed - output DLL not found." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Build error: $_" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Main execution
try {
    # Create lib directory if it doesn't exist
    if (-not (Test-Path $libDir)) {
        New-Item -ItemType Directory -Path $libDir | Out-Null
    }
    
    # Check if we need to download dependencies
    $bepInExExists = (Test-Path (Join-Path $libDir "BepInEx.dll"))
    $unityExists = (Test-Path (Join-Path $libDir "UnityEngine.dll"))
    
    if (-not $SkipDownload) {
        if (-not $bepInExExists) {
            if (-not (Get-BepInExLibraries)) {
                Write-Host ""
                Write-Host "WARNING: Could not download BepInEx libraries." -ForegroundColor Yellow
                Write-Host "Build may fail without these libraries." -ForegroundColor Yellow
            }
        } else {
            Write-Host "BepInEx libraries already present." -ForegroundColor Green
        }
        
        if (-not $unityExists) {
            if (-not (Get-UnityLibraries -ProvidedFM26Path $FM26Path)) {
                Write-Host ""
                Write-Host "WARNING: Could not obtain Unity libraries." -ForegroundColor Yellow
                Write-Host "Build may fail without these libraries." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Unity libraries already present." -ForegroundColor Green
        }
    }
    
    # Attempt build
    if (-not (Build-Plugin)) {
        Write-Host ""
        Write-Host "Build failed. Please ensure all dependencies are in the lib folder." -ForegroundColor Red
        Write-Host "See lib/README.md for required files." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Build Complete!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "An error occurred: $_" -ForegroundColor Red
    exit 1
}
