# FM26 Accessibility Mod Installer
# This script automatically installs the FM26 accessibility mod and all dependencies

param(
    [string]$FM26Path = "",
    [switch]$Uninstall = $false,
    [switch]$Force = $false,
    [string]$BepInExVersion = "6.0.0-pre.2"
)

$ErrorActionPreference = "Stop"

# ── Logging Setup ──────────────────────────────────────────────────────
# All terminal output is mirrored to a log file that is overwritten each run.
$LogFile = Join-Path $PSScriptRoot "install-log.log"
try {
    # Stop any previous transcript that may still be open
    Stop-Transcript -ErrorAction SilentlyContinue 2>$null
} catch {}
Start-Transcript -Path $LogFile -Force | Out-Null
Write-Host "[LOG] Logging all output to: $LogFile"
Write-Host "[LOG] Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# Script configuration
$ModName = "FM26 Accessibility Mod"
$ModVersion = "1.0.0"
$BepInExDownloadUrl = "https://github.com/BepInEx/BepInEx/releases/download/v$BepInExVersion/BepInEx-Unity.IL2CPP-win-x64-$BepInExVersion.zip"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  $ModName Installer v$ModVersion" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── System diagnostics ─────────────────────────────────────────────────
Write-Host "--- System Information ---" -ForegroundColor Cyan
Write-Host "  OS:             $([System.Environment]::OSVersion.VersionString)"
Write-Host "  PowerShell:     $($PSVersionTable.PSVersion)"
Write-Host "  Architecture:   $([System.Environment]::Is64BitOperatingSystem | ForEach-Object { if ($_) {'64-bit'} else {'32-bit'} })"
Write-Host "  User:           $([System.Environment]::UserName)"
Write-Host "  Admin:          $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
Write-Host "  Working Dir:    $(Get-Location)"
Write-Host "  Script Dir:     $PSScriptRoot"
Write-Host "  Temp Dir:       $env:TEMP"
try {
    $dotnetVer = & dotnet --version 2>$null
    if ($dotnetVer) { Write-Host "  .NET SDK:       $dotnetVer" }
    else           { Write-Host "  .NET SDK:       not found on PATH" -ForegroundColor Yellow }
} catch {
    Write-Host "  .NET SDK:       not found on PATH" -ForegroundColor Yellow
}
Write-Host "  BepInEx target: v$BepInExVersion"
Write-Host "  Download URL:   $BepInExDownloadUrl"
Write-Host ""

# Function to find FM26 installation
function Find-FM26Installation {
    Write-Host "Searching for Football Manager 2026 installation..." -ForegroundColor Yellow
    
    $possiblePaths = @(
        # Steam default locations
        "C:\Program Files (x86)\Steam\steamapps\common\Football Manager 2026",
        "C:\Program Files\Steam\steamapps\common\Football Manager 2026",
        "D:\Steam\steamapps\common\Football Manager 2026",
        "E:\Steam\steamapps\common\Football Manager 2026",
        # Xbox Game Pass
        "C:\Program Files\WindowsApps\Sports Interactive.FM2026",
        "C:\XboxGames\Football Manager 2026",
        # Epic Games
        "C:\Program Files\Epic Games\Football Manager 2026"
    )
    
    # Check registry for Steam
    try {
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue).SteamPath
        if ($steamPath) {
            $steamPath = $steamPath.Replace('/', '\')
            $possiblePaths += "$steamPath\steamapps\common\Football Manager 2026"
        }
    } catch {
        # Silent failure - registry key not available on non-Steam installations or restricted access
    }

    # Check each possible path in order
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $exePath = Join-Path $path "fm.exe"
            if (Test-Path $exePath) {
                Write-Host "  Found FM26 at: $path" -ForegroundColor Green
                return $path
            }
        }
    }
    return $null
}

# Function to download file with progress and retry
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [int]$MaxRetries = 3
    )
    
    Write-Host "Downloading from: $Url" -ForegroundColor Yellow
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            if ($i -gt 1) {
                Write-Host "  Retry attempt $i of $MaxRetries..." -ForegroundColor Yellow
            }
            
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "FM26-Accessibility-Mod-Installer/1.0")
            
            $webClient.DownloadFile($Url, $OutputPath)
            
            # Verify file was downloaded and has size > 0
            if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
                Write-Host "  Download complete!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "  [ERROR] Downloaded file is empty or missing at $OutputPath" -ForegroundColor Red
                if ($i -lt $MaxRetries) { Start-Sleep -Seconds 2 }
            }
        } catch {
            Write-Host "  [ERROR] Download failed on attempt $i : $($_.Exception.GetType().FullName)" -ForegroundColor Red
            Write-Host "  [ERROR] Message: $($_.Exception.Message)" -ForegroundColor Red
            if ($_.Exception.InnerException) {
                Write-Host "  [ERROR] Inner: $($_.Exception.InnerException.Message)" -ForegroundColor Red
            }
            if ($i -lt $MaxRetries) {
                Start-Sleep -Seconds 2
            }
        }
    }
    
    Write-Host "  [ERROR] Failed to download after $MaxRetries attempts." -ForegroundColor Red
    return $false
}

# Function to extract zip file with overwrite support
function Extract-ZipFile {
    param(
        [string]$ZipPath,
        [string]$DestPath
    )
    
    Write-Host "Extracting to: $DestPath" -ForegroundColor Yellow
    
    try {
        # Validate zip file exists and is not empty
        if (-not (Test-Path $ZipPath)) {
            Write-Host "  [ERROR] Zip file not found: $ZipPath" -ForegroundColor Red
            return $false
        }
        
        $zipSize = (Get-Item $ZipPath).Length
        if ($zipSize -eq 0) {
            Write-Host "  [ERROR] Zip file is empty (0 bytes): $ZipPath" -ForegroundColor Red
            return $false
        }
        
        # Use .NET for extraction with overwrite support
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        
        # Open the zip file for reading
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        
        try {
            $filesOverwritten = 0
            $filesCreated = 0
            
            foreach ($entry in $zip.Entries) {
                $targetPath = Join-Path $DestPath $entry.FullName
                
                # Security: Validate path to prevent ZIP slip attacks
                $fullTargetPath = [System.IO.Path]::GetFullPath($targetPath)
                $fullDestPath = [System.IO.Path]::GetFullPath($DestPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
                $fullDestPath = $fullDestPath + [System.IO.Path]::DirectorySeparatorChar
                if (-not $fullTargetPath.StartsWith($fullDestPath, [StringComparison]::OrdinalIgnoreCase)) {
                    Write-Host "  [WARNING] Skipping potentially malicious entry: $($entry.FullName)" -ForegroundColor Yellow
                    continue
                }
                
                # Handle directory entries (per ZIP spec, directories end with /)
                # Check for backslash too for robustness with non-standard ZIPs
                if ($entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')) {
                    # Create the directory if it doesn't exist
                    if (-not (Test-Path $targetPath)) {
                        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                    }
                    continue
                }
                
                # For file entries, ensure parent directory exists
                $targetDir = Split-Path $targetPath -Parent
                if ($targetDir -and -not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                
                # Remove existing file if present
                if (Test-Path $targetPath) {
                    Remove-Item $targetPath -Force
                    $filesOverwritten++
                } else {
                    $filesCreated++
                }
                
                # Extract the file (works for both empty and non-empty files)
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath)
            }
            
            Write-Host "  Extraction complete! (Created: $filesCreated, Overwritten: $filesOverwritten)" -ForegroundColor Green
            return $true
        } finally {
            $zip.Dispose()
        }
    } catch {
        Write-Host "  [ERROR] Extraction failed: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        Write-Host "  [ERROR] Message: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.InnerException) {
            Write-Host "  [ERROR] Inner: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        }
        Write-Host "  [HINT]  This may happen if the zip file is corrupted or the destination path" -ForegroundColor Yellow
        Write-Host "          has permission issues. Try running as Administrator." -ForegroundColor Yellow
        return $false
    }
}

# Function to install BepInEx
function Install-BepInEx {
    param([string]$GamePath)
    
    $bepInExPath = Join-Path $GamePath "BepInEx"
    
    if ((Test-Path $bepInExPath) -and -not $Force) {
        Write-Host "BepInEx directory already exists." -ForegroundColor Green
        
        # Verify core files exist (BepInEx 6 IL2CPP layout)
        $coreFile = Join-Path $GamePath "BepInEx\core\BepInEx.IL2CPP.dll"
        $coreFileFallback = Join-Path $GamePath "BepInEx\core\BepInEx.Unity.IL2CPP.dll"
        if (-not ((Test-Path $coreFile) -or (Test-Path $coreFileFallback))) {
            Write-Host "  [WARNING] BepInEx 6 IL2CPP installation appears incomplete. Reinstalling..." -ForegroundColor Yellow
        } else {
            return $true
        }
    }
    
    Write-Host ""
    Write-Host "Installing BepInEx $BepInExVersion (IL2CPP)..." -ForegroundColor Cyan
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "FM26Mod_Temp"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Download BepInEx
    $zipPath = Join-Path $tempDir "BepInEx.zip"
    Write-Host "Downloading BepInEx 6 IL2CPP..."
    if (-not (Download-File -Url $BepInExDownloadUrl -OutputPath $zipPath)) {
        Write-Host "  [ERROR] Failed to download BepInEx. Check your internet connection and that the URL is reachable." -ForegroundColor Red
        Write-Host "  [HINT]  You can try downloading manually from https://github.com/BepInEx/BepInEx/releases" -ForegroundColor Yellow
        return $false
    }
    
    # Extract BepInEx
    Write-Host "Installing BepInEx to game directory..."
    if (-not (Extract-ZipFile -ZipPath $zipPath -DestPath $GamePath)) {
        Write-Host "  [ERROR] Failed to extract BepInEx." -ForegroundColor Red
        Write-Host "  [HINT]  You may need to run as Administrator, or the destination may already have files." -ForegroundColor Yellow
        return $false
    }
    
    # Verify installation (BepInEx 6 IL2CPP structure)
    $bepInExCoreDir = Join-Path $GamePath "BepInEx\core"
    if (-not (Test-Path $bepInExCoreDir)) {
        Write-Host "  [ERROR] BepInEx installation verification failed. Core directory not found." -ForegroundColor Red
        return $false
    }
    
    # Clean up
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "BepInEx 6 IL2CPP installed successfully!" -ForegroundColor Green
    return $true
}

# Function to install NVDA Controller Client
function Install-NVDAControllerClient {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "Installing NVDA Controller Client..." -ForegroundColor Cyan
    
    $pluginsPath = Join-Path $GamePath "BepInEx\plugins"
    $nvdaDllPath = Join-Path $pluginsPath "nvdaControllerClient64.dll"
    
    # Ensure plugins directory exists
    if (-not (Test-Path $pluginsPath)) {
        New-Item -ItemType Directory -Path $pluginsPath -Force | Out-Null
    }
    
    # Check if already installed
    if ((Test-Path $nvdaDllPath) -and -not $Force) {
        Write-Host "NVDA Controller Client already installed. Skipping." -ForegroundColor Green
        return $true
    }
    
    # --- Strategy: check local sources first, then download ---
    
    # 1. Check bundled lib folder (ships with the release zip)
    #    Try both flat layout (script at root) and repo layout (script in install/)
    $libCandidates = @(
        (Join-Path $PSScriptRoot "lib"),
        (Join-Path (Split-Path -Parent $PSScriptRoot) "lib")
    )
    foreach ($libDir in $libCandidates) {
        $sourceNvdaDll = Join-Path $libDir "nvdaControllerClient64.dll"
        if (Test-Path $sourceNvdaDll) {
            Copy-Item -Path $sourceNvdaDll -Destination $nvdaDllPath -Force
            Write-Host "NVDA Controller Client installed from bundled files!" -ForegroundColor Green
            return $true
        }
    }
    
    # 2. Check same directory as installer (in case user placed it there)
    $localNvdaDll = Join-Path $PSScriptRoot "nvdaControllerClient64.dll"
    
    if (Test-Path $localNvdaDll) {
        Copy-Item -Path $localNvdaDll -Destination $nvdaDllPath -Force
        Write-Host "NVDA Controller Client installed from local files!" -ForegroundColor Green
        return $true
    }
    
    # 3. Check if NVDA is installed on the system and copy from there
    $nvdaPaths = @(
        "$env:ProgramFiles\NVDA\lib64\nvdaControllerClient64.dll",
        "${env:ProgramFiles(x86)}\NVDA\lib64\nvdaControllerClient64.dll",
        "$env:ProgramFiles\NVDA\nvdaControllerClient64.dll",
        "${env:ProgramFiles(x86)}\NVDA\nvdaControllerClient64.dll"
    )
    
    foreach ($nvdaPath in $nvdaPaths) {
        if (Test-Path $nvdaPath) {
            Write-Host "  Found NVDA Controller Client in system NVDA installation!" -ForegroundColor Green
            Copy-Item -Path $nvdaPath -Destination $nvdaDllPath -Force
            Write-Host "NVDA Controller Client installed from system NVDA!" -ForegroundColor Green
            return $true
        }
    }
    
    # 4. Try to download from the internet (NVDA controllerClient zip)
    Write-Host "  [INFO] NVDA Controller Client not found locally. Attempting download..." -ForegroundColor Yellow
    $nvdaControllerUrl = "https://download.nvaccess.org/releases/stable/nvda_2025.3.3_controllerClient.zip"
    $tempDir = Join-Path $env:TEMP "FM26Mod_NVDATemp"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $tempZip = Join-Path $tempDir "nvda_controllerClient.zip"
    
    $downloadSuccess = Download-File -Url $nvdaControllerUrl -OutputPath $tempZip -MaxRetries 2
    if ($downloadSuccess) {
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            
            # Extract with overwrite support (using same approach as Extract-ZipFile)
            $zip = [System.IO.Compression.ZipFile]::OpenRead($tempZip)
            try {
                foreach ($entry in $zip.Entries) {
                    $targetPath = Join-Path $tempDir $entry.FullName
                    
                    # Security: Validate path to prevent ZIP slip attacks
                    $fullTargetPath = [System.IO.Path]::GetFullPath($targetPath)
                    $fullTempDir = [System.IO.Path]::GetFullPath($tempDir).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
                    $fullTempDir = $fullTempDir + [System.IO.Path]::DirectorySeparatorChar
                    if (-not $fullTargetPath.StartsWith($fullTempDir, [StringComparison]::OrdinalIgnoreCase)) {
                        Write-Host "  [WARNING] Skipping potentially malicious entry: $($entry.FullName)" -ForegroundColor Yellow
                        continue
                    }
                    
                    # Handle directory entries (per ZIP spec, directories end with /)
                    # Check for backslash too for robustness with non-standard ZIPs
                    if ($entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')) {
                        if (-not (Test-Path $targetPath)) {
                            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                        }
                        continue
                    }
                    
                    # For file entries, ensure parent directory exists
                    $targetDir = Split-Path $targetPath -Parent
                    if ($targetDir -and -not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }
                    
                    # Remove existing file if present
                    if (Test-Path $targetPath) {
                        Remove-Item $targetPath -Force
                    }
                    
                    # Extract the file (works for both empty and non-empty files)
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath)
                }
            } finally {
                $zip.Dispose()
            }
            
            $extractedDll = Join-Path $tempDir "x64\nvdaControllerClient64.dll"
            if (Test-Path $extractedDll) {
                Copy-Item -Path $extractedDll -Destination $nvdaDllPath -Force
                Write-Host "NVDA Controller Client downloaded and installed!" -ForegroundColor Green
            } else {
                Write-Host "  [WARNING] Could not find nvdaControllerClient64.dll in downloaded archive." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  [WARNING] Failed to extract NVDA Controller Client: $($_.Exception.Message)" -ForegroundColor Yellow
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $nvdaDllPath) { return $true }
    }
    
    # 5. If all methods fail, inform the user but don't fail installation
    Write-Host ""
    Write-Host "  [INFO] Could not obtain NVDA Controller Client DLL." -ForegroundColor Yellow
    Write-Host "  [INFO] The mod will still work using Windows SAPI as a fallback." -ForegroundColor Yellow
    Write-Host "  [INFO] For enhanced NVDA support, you can:" -ForegroundColor Yellow
    Write-Host "         1. Install NVDA (https://www.nvaccess.org/download/)" -ForegroundColor White
    Write-Host "         2. Place nvdaControllerClient64.dll in: $pluginsPath" -ForegroundColor White
    Write-Host ""
    
    return $true  # Don't fail installation if NVDA client is missing
}

# Function to attempt automatic build of the plugin
function Build-PluginAutomatically {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "  [INFO] Attempting to build the plugin automatically..." -ForegroundColor Cyan
    Write-Host ""
    
    # Check if we're in a repository structure
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $projectFile = Join-Path $repoRoot "src\FM26AccessibilityPlugin\FM26AccessibilityPlugin.csproj"
    $buildScript = Join-Path $repoRoot "build\build.ps1"
    
    if (-not (Test-Path $projectFile)) {
        Write-Host "  [INFO] Automatic build requires the full repository structure." -ForegroundColor Yellow
        return $false
    }
    
    # Check if .NET SDK is available
    Write-Host "  [INFO] Checking for .NET SDK..." -ForegroundColor Cyan
    try {
        $dotnetVersion = & dotnet --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet command failed"
        }
        Write-Host "  [SUCCESS] .NET SDK version: $dotnetVersion" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "  [ERROR] .NET SDK not found or not functional." -ForegroundColor Red
        Write-Host ""
        Write-Host "  The .NET SDK is required to build the plugin automatically." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Please install it from:" -ForegroundColor Cyan
        Write-Host "    https://dotnet.microsoft.com/download" -ForegroundColor White
        Write-Host ""
        Write-Host "  After installation:" -ForegroundColor Cyan
        Write-Host "    1. Restart PowerShell" -ForegroundColor White
        Write-Host "    2. Run this installer again" -ForegroundColor White
        Write-Host ""
        return $false
    }
    
    # Use the build script if available
    if (Test-Path $buildScript) {
        Write-Host "  [INFO] Using build script: build.ps1" -ForegroundColor Cyan
        Write-Host "  [INFO] This will:" -ForegroundColor Cyan
        Write-Host "         - Download BepInEx libraries" -ForegroundColor White
        Write-Host "         - Copy Unity assemblies from your FM26 installation" -ForegroundColor White
        Write-Host "         - Build the accessibility plugin" -ForegroundColor White
        Write-Host ""
        
        try {
            Push-Location $repoRoot
            & $buildScript -FM26Path $GamePath
            $buildResult = $LASTEXITCODE
            Pop-Location
            
            if ($buildResult -eq 0) {
                Write-Host "  [SUCCESS] Plugin built successfully!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "  [WARNING] Build script completed with errors." -ForegroundColor Yellow
                # Check if DLL was created anyway
                $dllPath = Join-Path $repoRoot "build\FM26AccessibilityPlugin.dll"
                if (Test-Path $dllPath) {
                    Write-Host "  [INFO] Plugin DLL was created despite errors." -ForegroundColor Green
                    return $true
                }
                return $false
            }
        } catch {
            Write-Host "  [ERROR] Build failed: $_" -ForegroundColor Red
            Pop-Location
            return $false
        }
    } else {
        Write-Host "  [INFO] Build script not found. Attempting direct build..." -ForegroundColor Cyan
        
        # Create lib directories
        $libPath = Join-Path $repoRoot "lib"
        $interopPath = Join-Path $libPath "interop"
        if (-not (Test-Path $libPath)) {
            New-Item -ItemType Directory -Path $libPath -Force | Out-Null
        }
        if (-not (Test-Path $interopPath)) {
            New-Item -ItemType Directory -Path $interopPath -Force | Out-Null
        }
        
        # BepInEx 6 dependencies are resolved via NuGet; no manual download needed
        Write-Host "  [INFO] BepInEx 6 dependencies will be resolved via NuGet restore." -ForegroundColor Cyan
        
        # Check for IL2CPP build and generate interop assemblies
        $gameAssembly = Join-Path $GamePath "GameAssembly.dll"
        $globalMetadata = Join-Path $GamePath "fm_Data\il2cpp_data\Metadata\global-metadata.dat"
        
        if ((Test-Path $gameAssembly) -and (Test-Path $globalMetadata)) {
            Write-Host "  [INFO] IL2CPP build detected. Interop assemblies needed." -ForegroundColor Cyan
            Write-Host "  [INFO] Checking for Cpp2IL..." -ForegroundColor Cyan
            
            # Check for Cpp2IL in multiple locations
            $cpp2ilPath = $null
            
            # 1. Check for standalone executable in script directory (most portable)
            $scriptDirExe = Join-Path $PSScriptRoot "Cpp2IL.exe"
            if (Test-Path $scriptDirExe) {
                $cpp2ilPath = $scriptDirExe
                Write-Host "  [INFO] Found Cpp2IL in script directory: $cpp2ilPath" -ForegroundColor Gray
            }
            
            # 2. Check for versioned executable in script directory (e.g., Cpp2IL-2022.0.7-Windows.exe)
            if (-not $cpp2ilPath) {
                $versionedExes = Get-ChildItem -Path $PSScriptRoot -Filter "Cpp2IL*.exe" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
                if ($versionedExes) {
                    $cpp2ilPath = $versionedExes[0].FullName
                    Write-Host "  [INFO] Found Cpp2IL in script directory: $cpp2ilPath" -ForegroundColor Gray
                    if ($versionedExes.Count -gt 1) {
                        Write-Host "  [INFO] Multiple Cpp2IL executables found. Using most recent: $($versionedExes[0].Name)" -ForegroundColor Yellow
                    }
                }
            }
            
            # 3. Check for standalone executable in common download locations
            if (-not $cpp2ilPath) {
                $downloadsDir = Join-Path $env:USERPROFILE "Downloads"
                if (Test-Path $downloadsDir) {
                    $downloadedExes = Get-ChildItem -Path $downloadsDir -Filter "Cpp2IL*.exe" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
                    if ($downloadedExes) {
                        $cpp2ilPath = $downloadedExes[0].FullName
                        Write-Host "  [INFO] Found Cpp2IL in Downloads: $cpp2ilPath" -ForegroundColor Gray
                        if ($downloadedExes.Count -gt 1) {
                            Write-Host "  [INFO] Multiple Cpp2IL executables found in Downloads. Using most recent: $($downloadedExes[0].Name)" -ForegroundColor Yellow
                        }
                    }
                }
            }
            
            # 4. Check if it's available as a command (global dotnet tool or in PATH)
            if (-not $cpp2ilPath) {
                try {
                    $cpp2ilOutput = & Cpp2IL --version 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $cpp2ilPath = "Cpp2IL"
                        Write-Host "  [INFO] Found Cpp2IL in PATH (global dotnet tool)" -ForegroundColor Gray
                    }
                } catch {
                    # Cpp2IL not available in PATH
                }
            }
            
            if ($cpp2ilPath) {
                Write-Host "  [INFO] Generating interop assemblies with Cpp2IL..." -ForegroundColor Cyan
                # Sanitize path for logging (remove user-specific parts)
                $sanitizedPath = $cpp2ilPath -replace [regex]::Escape($env:USERPROFILE), '~'
                $sanitizedGamePath = $GamePath -replace [regex]::Escape($env:USERPROFILE), '~'
                Write-Host "  [INFO] Command: & `"$sanitizedPath`" --game-path `"$sanitizedGamePath`" --output-as dummydll --output-to `"<interopPath>`"" -ForegroundColor Gray
                try {
                    # Use the call operator & to execute the Cpp2IL path
                    & $cpp2ilPath --game-path $GamePath --output-as "dummydll" --output-to $interopPath
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  [SUCCESS] Interop assemblies generated." -ForegroundColor Green
                    } else {
                        Write-Host "  [WARNING] Cpp2IL exited with code: $LASTEXITCODE" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "  [WARNING] Cpp2IL failed: $_" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [WARNING] Cpp2IL not found." -ForegroundColor Yellow
                Write-Host "  [INFO] You can install Cpp2IL by:" -ForegroundColor Cyan
                Write-Host "    - Option 1: Run 'dotnet tool install -g Cpp2IL' and restart PowerShell" -ForegroundColor White
                Write-Host "    - Option 2: Download Cpp2IL.exe and place it in: $PSScriptRoot" -ForegroundColor White
                Write-Host "  [WARNING] Interop assemblies must be provided manually in lib/interop/" -ForegroundColor Yellow
            }
        } else {
            # Fall back: check for Mono managed folder (unlikely for FM26 retail)
            $unityPath = Join-Path $GamePath "fm_Data\Managed"
            if (Test-Path $unityPath) {
                Write-Host "  [WARNING] Mono build detected. This plugin targets IL2CPP." -ForegroundColor Yellow
                Write-Host "  [WARNING] FM26 retail uses IL2CPP; check your game installation." -ForegroundColor Yellow
            } else {
                Write-Host "  [WARNING] Could not locate IL2CPP metadata or Mono assemblies." -ForegroundColor Yellow
            }
        }
        
        # Build the project
        Write-Host "  [INFO] Building plugin..." -ForegroundColor Cyan
        try {
            Push-Location $repoRoot
            & dotnet build "$projectFile" --configuration Release 2>&1 | ForEach-Object {
                if ($_ -match "error") {
                    Write-Host "  [BUILD ERROR] $_" -ForegroundColor Red
                } elseif ($_ -match "warning") {
                    Write-Host "  [BUILD WARN] $_" -ForegroundColor Yellow
                }
            }
            
            # Check if build succeeded (net6.0 output path)
            $builtDll = Join-Path $repoRoot "src\FM26AccessibilityPlugin\bin\Release\net6.0\FM26AccessibilityPlugin.dll"
            if (Test-Path $builtDll) {
                # Copy to build directory
                $buildDir = Join-Path $repoRoot "build"
                if (-not (Test-Path $buildDir)) {
                    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
                }
                Copy-Item -Path $builtDll -Destination $buildDir -Force
                Write-Host "  [SUCCESS] Plugin built successfully!" -ForegroundColor Green
                Pop-Location
                return $true
            } else {
                Write-Host "  [ERROR] Build completed but DLL not found." -ForegroundColor Red
                Pop-Location
                return $false
            }
        } catch {
            Write-Host "  [ERROR] Build failed: $_" -ForegroundColor Red
            Pop-Location
            return $false
        }
    }
}

# Function to install the accessibility plugin
function Install-AccessibilityPlugin {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "Installing FM26 Accessibility Plugin..." -ForegroundColor Cyan
    
    $pluginsPath = Join-Path $GamePath "BepInEx\plugins"
    
    if (-not (Test-Path $pluginsPath)) {
        New-Item -ItemType Directory -Path $pluginsPath -Force | Out-Null
    }
    
    # Get the directory where this script is located
    # Try both flat layout (script at root) and repo layout (script in install/)
    $sourcePluginPath = $null
    $pluginCandidates = @(
        (Join-Path $PSScriptRoot "build\FM26AccessibilityPlugin.dll"),
        (Join-Path (Split-Path -Parent $PSScriptRoot) "build\FM26AccessibilityPlugin.dll")
    )
    foreach ($candidate in $pluginCandidates) {
        if (Test-Path $candidate) {
            $sourcePluginPath = $candidate
            break
        }
    }
    
    # Check if plugin DLL exists
    if (-not $sourcePluginPath) {
        Write-Host "  [WARNING] Plugin DLL not found in package." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [INFO] Pre-built releases do not include the plugin DLL because" -ForegroundColor Cyan
        Write-Host "         it requires Unity assemblies from Football Manager 2026." -ForegroundColor Cyan
        Write-Host ""
        
        # Try automatic build
        Write-Host "  [INFO] Attempting to build the plugin automatically using your FM26 installation..." -ForegroundColor Cyan
        $buildSuccess = Build-PluginAutomatically -GamePath $GamePath
        
        if ($buildSuccess) {
            # Check again for the DLL after building
            foreach ($candidate in $pluginCandidates) {
                if (Test-Path $candidate) {
                    $sourcePluginPath = $candidate
                    Write-Host "  [SUCCESS] Plugin built and ready to install!" -ForegroundColor Green
                    break
                }
            }
        }
        
        # If still no DLL, provide guidance
        if (-not $sourcePluginPath) {
            Write-Host ""
            Write-Host "  [ERROR] Could not build the plugin automatically." -ForegroundColor Red
            Write-Host ""
            Write-Host "  To use this mod, you need to build the plugin. Options:" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Option 1: Manual Build (Recommended)" -ForegroundColor Cyan
            Write-Host "    1. Ensure .NET SDK is installed: https://dotnet.microsoft.com/download" -ForegroundColor White
            Write-Host "    2. Open PowerShell in the mod directory" -ForegroundColor White
            Write-Host "    3. Run: .\build\build.ps1 -FM26Path ""$GamePath""" -ForegroundColor White
            Write-Host "    4. Run this installer again" -ForegroundColor White
            Write-Host ""
            Write-Host "  Option 2: Use Repository" -ForegroundColor Cyan
            Write-Host "    1. Clone: https://github.com/MadnessInnsmouth/MadnessInnsmouth.git" -ForegroundColor White
            Write-Host "    2. Run: .\build\build.ps1" -ForegroundColor White
            Write-Host "    3. Run: .\install\Install-FM26Accessibility.ps1" -ForegroundColor White
            Write-Host ""
            Write-Host "  [INFO] Why pre-built DLLs aren't available:" -ForegroundColor Cyan
            Write-Host "         The plugin needs to reference Unity DLLs from FM26's installation," -ForegroundColor White
            Write-Host "         which cannot be legally redistributed in releases." -ForegroundColor White
            Write-Host ""
            Write-Host "  For more help, see: https://github.com/MadnessInnsmouth/MadnessInnsmouth/blob/main/BUILD.md" -ForegroundColor Cyan
            Write-Host ""
            return $false
        }
    }
    
    # Verify the DLL is valid
    $pluginSize = (Get-Item $sourcePluginPath).Length
    if ($pluginSize -eq 0) {
        Write-Host "  [ERROR] Plugin DLL is empty (0 bytes). It may be corrupted." -ForegroundColor Red
        return $false
    }
    
    # Copy plugin
    $destPluginPath = Join-Path $pluginsPath "FM26AccessibilityPlugin.dll"
    try {
        Copy-Item -Path $sourcePluginPath -Destination $destPluginPath -Force
        
        # Verify copy
        if (-not (Test-Path $destPluginPath)) {
            Write-Host "  [ERROR] Failed to copy plugin DLL to destination. File not found after copy." -ForegroundColor Red
            return $false
        }
        
        Write-Host "Accessibility plugin installed!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [ERROR] Failed to copy plugin: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        Write-Host "  [ERROR] Message: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create configuration
function Create-Configuration {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "Creating configuration files..." -ForegroundColor Cyan
    
    $configPath = Join-Path $GamePath "BepInEx\config"
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Path $configPath -Force | Out-Null
    }
    
    # Create a config file for the plugin
    $pluginConfig = @"
## Settings for FM26 Accessibility Plugin

[General]

## Enable screen reader support
# Setting type: Boolean
# Default value: true
EnableScreenReader = true

## Update interval for UI tracking (in seconds)
# Setting type: Single
# Default value: 0.1
UpdateInterval = 0.1

## Enable keyboard navigation
# Setting type: Boolean
# Default value: true
EnableKeyboardNav = true

[Debug]

## Enable debug logging
# Setting type: Boolean
# Default value: false
EnableDebugLogging = false
"@
    
    $configFile = Join-Path $configPath "com.accessibility.fm26.cfg"
    $pluginConfig | Out-File -FilePath $configFile -Encoding UTF8
    
    Write-Host "Configuration created!" -ForegroundColor Green
}

# Function to uninstall
function Uninstall-Mod {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "Uninstalling $ModName..." -ForegroundColor Yellow
    
    $pluginPath = Join-Path $GamePath "BepInEx\plugins\FM26AccessibilityPlugin.dll"
    
    if (Test-Path $pluginPath) {
        Remove-Item $pluginPath -Force
        Write-Host "Plugin removed." -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Plugin DLL was not found at: $pluginPath (already removed?)" -ForegroundColor Gray
    }
    
    Write-Host "Uninstall complete!" -ForegroundColor Green
    Write-Host "Note: BepInEx framework was not removed. Remove manually if desired." -ForegroundColor Yellow
}

# Main installation flow
function Main {
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "NOTE: Not running as administrator." -ForegroundColor Yellow
        Write-Host "  This is usually fine. The installer will request elevation only if needed." -ForegroundColor Yellow
        Write-Host "  [HINT] If you encounter permission errors later, right-click the installer and choose 'Run as Administrator'." -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Find FM26 installation
    $fm26Path = $FM26Path
    if ([string]::IsNullOrEmpty($fm26Path)) {
        $fm26Path = Find-FM26Installation
    }
    
    if ([string]::IsNullOrEmpty($fm26Path)) {
        Write-Host ""
        Write-Host "Could not find Football Manager 2026 installation automatically." -ForegroundColor Red
        Write-Host "Please enter the full path to your FM26 installation directory:" -ForegroundColor Yellow
        $fm26Path = Read-Host "FM26 Path"
        
        if (-not (Test-Path $fm26Path)) {
            Write-Host "  [ERROR] The path does not exist: $fm26Path" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "Installation Path: $fm26Path" -ForegroundColor Cyan
    Write-Host ""
    
    # Verify game directory looks valid
    $fmExe = Join-Path $fm26Path "fm.exe"
    if (-not (Test-Path $fmExe)) {
        Write-Host "  [WARNING] fm.exe not found in: $fm26Path" -ForegroundColor Yellow
        Write-Host "  [WARNING] This may not be a valid FM26 installation directory." -ForegroundColor Yellow
    }
    
    # Uninstall mode
    if ($Uninstall) {
        Uninstall-Mod -GamePath $fm26Path
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
    
    # Install BepInEx
    Write-Host "--- Step 1/4: BepInEx Framework ---" -ForegroundColor Cyan
    if (-not (Install-BepInEx -GamePath $fm26Path)) {
        Write-Host ""
        Write-Host "  [ERROR] Installation failed at BepInEx stage." -ForegroundColor Red
        Write-Host "  [HINT]  Check the log file for details: $LogFile" -ForegroundColor Yellow
        exit 1
    }
    
    # Install NVDA Controller Client
    Write-Host "--- Step 2/4: NVDA Controller Client ---" -ForegroundColor Cyan
    Install-NVDAControllerClient -GamePath $fm26Path
    
    # Install plugin
    Write-Host "--- Step 3/4: Accessibility Plugin ---" -ForegroundColor Cyan
    if (-not (Install-AccessibilityPlugin -GamePath $fm26Path)) {
        Write-Host ""
        Write-Host "  [ERROR] Installation failed at plugin stage." -ForegroundColor Red
        Write-Host "  [HINT]  Check the log file for details: $LogFile" -ForegroundColor Yellow
        Write-Host "  [INFO]  BepInEx is still installed and can be used with other mods." -ForegroundColor Yellow
        exit 1
    }
    
    # Create configuration
    Write-Host "--- Step 4/4: Configuration ---" -ForegroundColor Cyan
    Create-Configuration -GamePath $fm26Path
    
    # Success message
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Installation Complete!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "The FM26 Accessibility Mod has been installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installed Components:" -ForegroundColor Cyan
    Write-Host "  + BepInEx $BepInExVersion" -ForegroundColor White
    Write-Host "  + FM26 Accessibility Plugin" -ForegroundColor White
    
    # Check if NVDA Controller Client was installed
    $nvdaDll = Join-Path $fm26Path "BepInEx\plugins\nvdaControllerClient64.dll"
    if (Test-Path $nvdaDll) {
        Write-Host "  + NVDA Controller Client (for enhanced NVDA support)" -ForegroundColor White
    } else {
        Write-Host "  - NVDA Controller Client not installed (optional)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Launch Football Manager 2026" -ForegroundColor White
    Write-Host "2. Ensure your screen reader (NVDA, JAWS, or Narrator) is running" -ForegroundColor White
    Write-Host "3. Navigate menus using Tab and Arrow keys" -ForegroundColor White
    Write-Host "4. Check BepInEx\LogOutput.log if you encounter issues" -ForegroundColor White
    Write-Host ""
    Write-Host "A full log of this installer session was saved to:" -ForegroundColor Cyan
    Write-Host "  $LogFile" -ForegroundColor White
    Write-Host ""
    Write-Host "For support and updates, visit:" -ForegroundColor Cyan
    Write-Host "https://github.com/MadnessInnsmouth/MadnessInnsmouth" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Run main function
try {
    Main
} catch {
    Write-Host ""
    Write-Host "[FATAL ERROR] An unhandled error occurred during installation." -ForegroundColor Red
    Write-Host "[FATAL ERROR] Type:    $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "[FATAL ERROR] Message: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host "[FATAL ERROR] Stack trace:" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
    if ($_.Exception.InnerException) {
        Write-Host "[FATAL ERROR] Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "A full log of this session was saved to:" -ForegroundColor Yellow
    Write-Host "  $LogFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
} finally {
    try { Stop-Transcript -ErrorAction SilentlyContinue } catch {}
}
