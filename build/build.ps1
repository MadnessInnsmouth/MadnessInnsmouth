# FM26 Accessibility Plugin Build Script
# Downloads dependencies and builds the plugin
# Updated for BepInEx 6 (IL2CPP) support

param(
    [string]$Configuration = "Release",
    [string]$OutputPath = "",
    [switch]$SkipDownload = $false,
    [string]$FM26Path = ""
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  FM26 Accessibility Plugin Build Script" -ForegroundColor Cyan
Write-Host "  (BepInEx 6 / IL2CPP)" -ForegroundColor Cyan
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
    Write-Host "The .NET SDK (6.0 or later) is required to build the FM26 Accessibility Plugin." -ForegroundColor Yellow
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
$interopDir = Join-Path $libDir "interop"
$srcDir = Join-Path $rootDir "src\FM26AccessibilityPlugin"

# BepInEx 6 configuration (IL2CPP build)
$bepInExVersion = "6.0.0-pre.2"
$bepInExUrl = "https://github.com/BepInEx/BepInEx/releases/download/v$bepInExVersion/BepInEx-Unity.IL2CPP-win-x64-$bepInExVersion.zip"

# Function to detect IL2CPP vs Mono build
function Detect-GameRuntime {
    param([string]$GamePath)
    
    if ([string]::IsNullOrEmpty($GamePath)) { return $null }
    
    $gameAssembly = Join-Path $GamePath "GameAssembly.dll"
    $il2cppMetadata = Join-Path $GamePath "fm_Data\il2cpp_data\Metadata\global-metadata.dat"
    $managedFolder = Join-Path $GamePath "fm_Data\Managed"
    
    if ((Test-Path $gameAssembly) -and (Test-Path $il2cppMetadata)) {
        Write-Host "  Detected: IL2CPP build" -ForegroundColor Green
        Write-Host "    GameAssembly.dll: $gameAssembly" -ForegroundColor Gray
        Write-Host "    Metadata: $il2cppMetadata" -ForegroundColor Gray
        return "IL2CPP"
    }
    
    if (Test-Path $managedFolder) {
        Write-Host "  Detected: Mono build" -ForegroundColor Yellow
        Write-Host "    WARNING: This build script targets IL2CPP." -ForegroundColor Yellow
        Write-Host "    If you have a Mono build, use the legacy BepInEx 5 branch." -ForegroundColor Yellow
        return "Mono"
    }
    
    Write-Host "  Could not determine game runtime." -ForegroundColor Yellow
    return $null
}

# Function to download and extract BepInEx 6
function Get-BepInExLibraries {
    Write-Host "Downloading BepInEx 6 IL2CPP libraries..." -ForegroundColor Yellow
    
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
        Write-Host "Extracting BepInEx 6..."
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)
        
        Write-Host "BepInEx 6 IL2CPP libraries obtained successfully!" -ForegroundColor Green
        
        # Clean up
        Remove-Item $tempDir -Recurse -Force
        return $true
    } catch {
        Write-Host "Failed to download BepInEx 6: $_" -ForegroundColor Red
        return $false
    }
}

# Function to generate IL2CPP interop assemblies using Cpp2IL
function Generate-InteropAssemblies {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "Generating IL2CPP interop assemblies..." -ForegroundColor Yellow
    
    $gameAssembly = Join-Path $GamePath "GameAssembly.dll"
    $globalMetadata = Join-Path $GamePath "fm_Data\il2cpp_data\Metadata\global-metadata.dat"
    
    if (-not (Test-Path $gameAssembly)) {
        Write-Host "  GameAssembly.dll not found at: $gameAssembly" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path $globalMetadata)) {
        Write-Host "  global-metadata.dat not found at: $globalMetadata" -ForegroundColor Red
        return $false
    }
    
    # Create interop output directory
    if (-not (Test-Path $interopDir)) {
        New-Item -ItemType Directory -Path $interopDir | Out-Null
    }
    
    # Check if Cpp2IL is available - try multiple locations
    $cpp2ilPath = $null
    
    # 1. Check for standalone executable in script directory (most portable)
    $scriptDirExe = Join-Path $scriptDir "Cpp2IL.exe"
    if (Test-Path $scriptDirExe) {
        $cpp2ilPath = $scriptDirExe
        Write-Host "  Found Cpp2IL in script directory: $cpp2ilPath" -ForegroundColor Gray
    }
    
    # 2. Check for versioned executable in script directory (e.g., Cpp2IL-2022.0.7-Windows.exe)
    if (-not $cpp2ilPath) {
        $versionedExes = Get-ChildItem -Path $scriptDir -Filter "Cpp2IL*.exe" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($versionedExes) {
            $cpp2ilPath = $versionedExes[0].FullName
            Write-Host "  Found Cpp2IL in script directory: $cpp2ilPath" -ForegroundColor Gray
            if ($versionedExes.Count -gt 1) {
                Write-Host "  Note: Multiple Cpp2IL executables found. Using most recent: $($versionedExes[0].Name)" -ForegroundColor Yellow
            }
        }
    }
    
    # 3. Check for standalone executable in common download locations
    if (-not $cpp2ilPath) {
        $commonPaths = @(
            (Join-Path $env:USERPROFILE "Downloads\Cpp2IL.exe"),
            (Join-Path $env:USERPROFILE "Downloads\Cpp2IL-2022.0.7-Windows.exe"),
            (Join-Path $env:USERPROFILE "Downloads\Cpp2IL-Windows.exe")
        )
        
        # Also check for any Cpp2IL*.exe in Downloads
        $downloadsDir = Join-Path $env:USERPROFILE "Downloads"
        if (Test-Path $downloadsDir) {
            $downloadedExes = Get-ChildItem -Path $downloadsDir -Filter "Cpp2IL*.exe" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
            if ($downloadedExes) {
                $cpp2ilPath = $downloadedExes[0].FullName
                Write-Host "  Found Cpp2IL at: $cpp2ilPath" -ForegroundColor Gray
                if ($downloadedExes.Count -gt 1) {
                    Write-Host "  Note: Multiple Cpp2IL executables found in Downloads. Using most recent: $($downloadedExes[0].Name)" -ForegroundColor Yellow
                }
            }
        }
        
        # Fall back to specific paths if wildcard search didn't find anything
        if (-not $cpp2ilPath) {
            foreach ($path in $commonPaths) {
                if (Test-Path $path) {
                    $cpp2ilPath = $path
                    Write-Host "  Found Cpp2IL at: $cpp2ilPath" -ForegroundColor Gray
                    break
                }
            }
        }
    }
    
    # 4. Check if it's available as a global dotnet tool
    if (-not $cpp2ilPath) {
        try {
            $cpp2ilPath = (Get-Command "Cpp2IL" -ErrorAction SilentlyContinue).Source
        } catch {}
    }
    
    # 5. Check dotnet tool list to confirm it's installed
    if (-not $cpp2ilPath) {
        try {
            & dotnet tool list -g 2>&1 | Select-String "Cpp2IL" | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $cpp2ilPath = "Cpp2IL"
            }
        } catch {}
    }
    
    # Auto-install Cpp2IL if not found
    if (-not $cpp2ilPath) {
        Write-Host ""
        Write-Host "  Cpp2IL is not installed. Installing automatically..." -ForegroundColor Yellow
        Write-Host "  Running: dotnet tool install -g Cpp2IL" -ForegroundColor Gray
        
        try {
            $installOutput = & dotnet tool install -g Cpp2IL 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Cpp2IL installed successfully!" -ForegroundColor Green
                $cpp2ilPath = "Cpp2IL"
                
                # Refresh PATH to ensure Cpp2IL is accessible
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            } else {
                Write-Host "  Failed to install Cpp2IL automatically." -ForegroundColor Red
                Write-Host "  Please install manually: dotnet tool install -g Cpp2IL" -ForegroundColor Yellow
                Write-Host "  Then restart PowerShell and run this script again." -ForegroundColor Yellow
                return $false
            }
        } catch {
            Write-Host "  Error installing Cpp2IL: $_" -ForegroundColor Red
            Write-Host ""
            Write-Host "  Please install manually:" -ForegroundColor Yellow
            Write-Host "    1. Run: dotnet tool install -g Cpp2IL" -ForegroundColor White
            Write-Host "    2. Restart PowerShell" -ForegroundColor White
            Write-Host "    3. Run this script again" -ForegroundColor White
            Write-Host ""
            return $false
        }
    }
    
    if ($cpp2ilPath) {
        Write-Host "  Using Cpp2IL to generate interop assemblies..."
        # Sanitize path for logging (remove user-specific parts)
        $sanitizedPath = $cpp2ilPath -replace [regex]::Escape($env:USERPROFILE), '~'
        $sanitizedGamePath = $GamePath -replace [regex]::Escape($env:USERPROFILE), '~'
        Write-Host "  Command: & `"$sanitizedPath`" --game-path `"$sanitizedGamePath`" --output-as dummydll --output-to `"<interopDir>`"" -ForegroundColor Gray
        try {
            # Use the call operator & to execute the Cpp2IL path
            # This works whether $cpp2ilPath is a full path or just "Cpp2IL" from PATH
            & $cpp2ilPath --game-path $GamePath --output-as "dummydll" --output-to $interopDir
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Interop assemblies generated!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "  Cpp2IL exited with code: $LASTEXITCODE" -ForegroundColor Red
            }
        } catch {
            Write-Host "  Cpp2IL failed: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "  Unable to use Cpp2IL. To generate interop assemblies:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Option 1 - Install as dotnet global tool (recommended):" -ForegroundColor Cyan
    Write-Host "    1. Run: dotnet tool install -g Cpp2IL" -ForegroundColor White
    Write-Host "    2. Restart PowerShell" -ForegroundColor White
    Write-Host "    3. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "  Option 2 - Use standalone executable:" -ForegroundColor Cyan
    Write-Host "    1. Download Cpp2IL executable (e.g., Cpp2IL-2022.0.7-Windows.exe)" -ForegroundColor White
    Write-Host "    2. Place it in the script directory: $scriptDir" -ForegroundColor White
    Write-Host "    3. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "  Option 3 - Manual generation:" -ForegroundColor Cyan
    Write-Host "    1. Run Cpp2IL manually:" -ForegroundColor White
    Write-Host "       Cpp2IL --game-path `"$GamePath`" --output-as dummydll --output-to `"$interopDir`"" -ForegroundColor White
    Write-Host "    2. Or place pre-generated interop DLLs in: $interopDir" -ForegroundColor White
    Write-Host ""
    
    return $false
}

# Function to search for FM26 installation
function Find-FM26Installation {
    param([string]$ProvidedFM26Path = "")
    
    Write-Host ""
    Write-Host "Searching for FM26 installation..." -ForegroundColor Yellow
    
    $fm26Path = $null
    
    # If FM26Path was provided as parameter, use it first
    if (-not [string]::IsNullOrEmpty($ProvidedFM26Path)) {
        Write-Host "Using provided FM26 path: $ProvidedFM26Path" -ForegroundColor Green
        if (Test-Path $ProvidedFM26Path) {
            $fm26Path = $ProvidedFM26Path
        }
    }
    
    # If not found or not provided, try to auto-detect
    if (-not $fm26Path) {
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
                $fm26Path = $path
                break
            }
        }
    }
    
    if ($fm26Path) {
        Write-Host "Found FM26 at: $fm26Path" -ForegroundColor Green
        
        # Detect runtime
        $runtime = Detect-GameRuntime -GamePath $fm26Path
        
        if ($runtime -eq "IL2CPP") {
            # Generate interop assemblies
            $hasInterop = Generate-InteropAssemblies -GamePath $fm26Path
            return $hasInterop
        } elseif ($runtime -eq "Mono") {
            Write-Host ""
            Write-Host "NOTE: FM26 appears to be a Mono build." -ForegroundColor Yellow
            Write-Host "This version of the plugin targets IL2CPP." -ForegroundColor Yellow
            return $false
        }
    } else {
        Write-Host "Could not find FM26 installation." -ForegroundColor Yellow
        Write-Host "IL2CPP interop assemblies must be provided manually to lib/interop/ folder." -ForegroundColor Yellow
        return $false
    }
    
    return $false
}

# Main build process
function Build-Plugin {
    Write-Host ""
    Write-Host "Building FM26 Accessibility Plugin..." -ForegroundColor Cyan
    
    try {
        Push-Location $rootDir
        
        # Restore dependencies (uses NuGet.config for BepInEx feed)
        Write-Host "Restoring dependencies..."
        dotnet restore $srcDir\FM26AccessibilityPlugin.csproj
        
        # Build
        Write-Host "Building in $Configuration configuration..."
        dotnet build $srcDir\FM26AccessibilityPlugin.csproj --configuration $Configuration --no-restore
        
        $builtDll = Join-Path $srcDir "bin\$Configuration\net6.0\FM26AccessibilityPlugin.dll"
        
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
    # Create lib directories if they don't exist
    if (-not (Test-Path $libDir)) {
        New-Item -ItemType Directory -Path $libDir | Out-Null
    }
    if (-not (Test-Path $interopDir)) {
        New-Item -ItemType Directory -Path $interopDir | Out-Null
    }
    
    if (-not $SkipDownload) {
        # BepInEx 6 packages are obtained via NuGet restore, not manual download
        Write-Host "BepInEx 6 dependencies will be resolved via NuGet during restore." -ForegroundColor Green
        
        # Check for interop assemblies
        $hasInterop = (Test-Path (Join-Path $interopDir "Il2CppUnityEngine.CoreModule.dll"))
        
        if (-not $hasInterop) {
            if (-not (Find-FM26Installation -ProvidedFM26Path $FM26Path)) {
                Write-Host ""
                Write-Host "WARNING: IL2CPP interop assemblies not available." -ForegroundColor Yellow
                Write-Host "Build may fail without these assemblies." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "To generate them:" -ForegroundColor Cyan
                Write-Host "  1. Run this script with -FM26Path pointing to your FM26 installation" -ForegroundColor White
                Write-Host "     The script will auto-install Cpp2IL if needed" -ForegroundColor Gray
                Write-Host "  2. Or manually place interop DLLs in: $interopDir" -ForegroundColor White
            }
        } else {
            Write-Host "IL2CPP interop assemblies already present." -ForegroundColor Green
        }
    }
    
    # Attempt build
    if (-not (Build-Plugin)) {
        Write-Host ""
        Write-Host "Build failed. Please ensure all dependencies are available." -ForegroundColor Red
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
