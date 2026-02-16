# FM26 Accessibility Mod Installer
# This script automatically installs the FM26 accessibility mod and all dependencies

param(
    [string]$FM26Path = "",
    [switch]$Uninstall = $false,
    [switch]$Force = $false,
    [string]$BepInExVersion = "5.4.23.2"
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
$BepInExDownloadUrl = "https://github.com/BepInEx/BepInEx/releases/download/v$BepInExVersion/BepInEx_win_x64_$BepInExVersion.zip"

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
            Write-Host "  [VERBOSE] Steam path from registry: $steamPath" -ForegroundColor Gray
        } else {
            Write-Host "  [VERBOSE] Steam path not found in registry." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [VERBOSE] Could not read Steam registry key: $_" -ForegroundColor Gray
    }

    # Check each possible path in order
    foreach ($path in $possiblePaths) {
        Write-Host "  [VERBOSE] Checking: $path" -ForegroundColor Gray
        if (Test-Path $path) {
            $exePath = Join-Path $path "fm.exe"
            Write-Host "  [VERBOSE]   Directory exists. Looking for fm.exe..." -ForegroundColor Gray
            if (Test-Path $exePath) {
                Write-Host "  Found FM26 at: $path" -ForegroundColor Green
                return $path
            } else {
                Write-Host "  [VERBOSE]   fm.exe not found in this directory." -ForegroundColor Gray
            }
        } else {
            Write-Host "  [VERBOSE]   Directory does not exist." -ForegroundColor Gray
        }
    }
    
    Write-Host "  [VERBOSE] FM26 was not found in any of the $($possiblePaths.Count) checked locations." -ForegroundColor Gray
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
    Write-Host "  [VERBOSE] Destination: $OutputPath" -ForegroundColor Gray
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            if ($i -gt 1) {
                Write-Host "  Retry attempt $i of $MaxRetries..." -ForegroundColor Yellow
            }
            
            Write-Host "  [VERBOSE] Creating WebClient (attempt $i)..." -ForegroundColor Gray
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "FM26-Accessibility-Mod-Installer/1.0")
            
            Write-Host "  [VERBOSE] Starting download..." -ForegroundColor Gray
            $webClient.DownloadFile($Url, $OutputPath)
            
            # Verify file was downloaded and has size > 0
            if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
                $fileSize = (Get-Item $OutputPath).Length
                Write-Host "  Download complete! File size: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Green
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
                Write-Host "  [VERBOSE] Waiting 2 seconds before retry..." -ForegroundColor Gray
                Start-Sleep -Seconds 2
            }
        }
    }
    
    Write-Host "  [ERROR] Failed to download after $MaxRetries attempts." -ForegroundColor Red
    return $false
}

# Function to extract zip file
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
        
        Write-Host "  [VERBOSE] Zip file size: $([math]::Round($zipSize / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "  [VERBOSE] Loading System.IO.Compression.FileSystem assembly..." -ForegroundColor Gray
        
        # Use .NET for extraction
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        
        Write-Host "  [VERBOSE] Extracting archive contents..." -ForegroundColor Gray
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $DestPath)
        
        Write-Host "  Extraction complete!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [ERROR] Extraction failed: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        Write-Host "  [ERROR] Message: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.InnerException) {
            Write-Host "  [ERROR] Inner: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        }
        Write-Host "  [HINT]  This may happen if the zip file is corrupted, the destination already exists," -ForegroundColor Yellow
        Write-Host "          or the destination path has permission issues. Try running as Administrator." -ForegroundColor Yellow
        return $false
    }
}

# Function to install BepInEx
function Install-BepInEx {
    param([string]$GamePath)
    
    $bepInExPath = Join-Path $GamePath "BepInEx"
    Write-Host "  [VERBOSE] Checking BepInEx at: $bepInExPath" -ForegroundColor Gray
    
    if ((Test-Path $bepInExPath) -and -not $Force) {
        Write-Host "BepInEx directory already exists." -ForegroundColor Green
        
        # Verify core files exist
        $coreFile = Join-Path $GamePath "BepInEx\core\BepInEx.dll"
        Write-Host "  [VERBOSE] Verifying core file: $coreFile" -ForegroundColor Gray
        if (-not (Test-Path $coreFile)) {
            Write-Host "  [WARNING] BepInEx installation appears incomplete (BepInEx.dll missing). Reinstalling..." -ForegroundColor Yellow
        } else {
            $coreSize = (Get-Item $coreFile).Length
            Write-Host "  [VERBOSE] BepInEx.dll found ($([math]::Round($coreSize / 1KB, 2)) KB). Skipping reinstall." -ForegroundColor Gray
            return $true
        }
    }
    
    Write-Host ""
    Write-Host "Installing BepInEx $BepInExVersion..." -ForegroundColor Cyan
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "FM26Mod_Temp"
    Write-Host "  [VERBOSE] Temp directory: $tempDir" -ForegroundColor Gray
    if (Test-Path $tempDir) {
        Write-Host "  [VERBOSE] Removing previous temp directory..." -ForegroundColor Gray
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Download BepInEx
    $zipPath = Join-Path $tempDir "BepInEx.zip"
    Write-Host "Downloading BepInEx..."
    Write-Host "  [VERBOSE] Target URL: $BepInExDownloadUrl" -ForegroundColor Gray
    if (-not (Download-File -Url $BepInExDownloadUrl -OutputPath $zipPath)) {
        Write-Host "  [ERROR] Failed to download BepInEx. Check your internet connection and that the URL is reachable." -ForegroundColor Red
        Write-Host "  [HINT]  You can try downloading manually from https://github.com/BepInEx/BepInEx/releases" -ForegroundColor Yellow
        return $false
    }
    
    # Extract BepInEx
    Write-Host "Installing BepInEx to game directory..."
    Write-Host "  [VERBOSE] Extracting to: $GamePath" -ForegroundColor Gray
    if (-not (Extract-ZipFile -ZipPath $zipPath -DestPath $GamePath)) {
        Write-Host "  [ERROR] Failed to extract BepInEx." -ForegroundColor Red
        Write-Host "  [HINT]  You may need to run as Administrator, or the destination may already have files." -ForegroundColor Yellow
        return $false
    }
    
    # Verify installation
    $coreFile = Join-Path $GamePath "BepInEx\core\BepInEx.dll"
    Write-Host "  [VERBOSE] Verifying installation: checking $coreFile" -ForegroundColor Gray
    if (-not (Test-Path $coreFile)) {
        Write-Host "  [ERROR] BepInEx installation verification failed. Core file not found at: $coreFile" -ForegroundColor Red
        # List what was actually extracted
        Write-Host "  [VERBOSE] Contents of BepInEx directory:" -ForegroundColor Gray
        if (Test-Path $bepInExPath) {
            Get-ChildItem -Path $bepInExPath -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "    $($_.FullName)" -ForegroundColor Gray
            }
        } else {
            Write-Host "    (directory does not exist)" -ForegroundColor Gray
        }
        return $false
    }
    
    # Clean up
    Write-Host "  [VERBOSE] Cleaning up temp directory..." -ForegroundColor Gray
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "BepInEx installed successfully!" -ForegroundColor Green
    return $true
}

# Function to install NVDA Controller Client
function Install-NVDAControllerClient {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "Installing NVDA Controller Client..." -ForegroundColor Cyan
    
    $pluginsPath = Join-Path $GamePath "BepInEx\plugins"
    $nvdaDllPath = Join-Path $pluginsPath "nvdaControllerClient64.dll"
    Write-Host "  [VERBOSE] Target path: $nvdaDllPath" -ForegroundColor Gray
    
    # Ensure plugins directory exists
    if (-not (Test-Path $pluginsPath)) {
        New-Item -ItemType Directory -Path $pluginsPath -Force | Out-Null
    }
    
    # Check if already installed
    if ((Test-Path $nvdaDllPath) -and -not $Force) {
        $dllSize = (Get-Item $nvdaDllPath).Length
        Write-Host "NVDA Controller Client already installed ($([math]::Round($dllSize / 1KB, 2)) KB). Skipping." -ForegroundColor Green
        return $true
    }
    
    # --- Strategy: check local sources first, then download ---
    
    # 1. Check bundled lib folder (ships with the release zip)
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $libDir = Join-Path (Split-Path -Parent $scriptDir) "lib"
    $sourceNvdaDll = Join-Path $libDir "nvdaControllerClient64.dll"
    Write-Host "  [VERBOSE] Looking for bundled copy at: $sourceNvdaDll" -ForegroundColor Gray
    
    if (Test-Path $sourceNvdaDll) {
        Write-Host "  [VERBOSE] Found bundled NVDA Controller Client. Copying..." -ForegroundColor Gray
        Copy-Item -Path $sourceNvdaDll -Destination $nvdaDllPath -Force
        Write-Host "NVDA Controller Client installed from bundled files!" -ForegroundColor Green
        return $true
    }
    
    # 2. Check same directory as installer (in case user placed it there)
    $localNvdaDll = Join-Path $scriptDir "nvdaControllerClient64.dll"
    Write-Host "  [VERBOSE] Looking for local copy at: $localNvdaDll" -ForegroundColor Gray
    
    if (Test-Path $localNvdaDll) {
        Write-Host "  [VERBOSE] Found local NVDA Controller Client. Copying..." -ForegroundColor Gray
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
        Write-Host "  [VERBOSE] Checking system NVDA installation: $nvdaPath" -ForegroundColor Gray
        if (Test-Path $nvdaPath) {
            Write-Host "  Found NVDA Controller Client in system NVDA installation!" -ForegroundColor Green
            Copy-Item -Path $nvdaPath -Destination $nvdaDllPath -Force
            Write-Host "NVDA Controller Client installed from system NVDA!" -ForegroundColor Green
            return $true
        }
    }
    
    # 4. Try to download from the internet
    Write-Host "  [INFO] NVDA Controller Client not found locally. Attempting download..." -ForegroundColor Yellow
    $nvdaControllerUrl = "https://github.com/nvaccess/nvda/blob/master/extras/controllerClient/x64/nvdaControllerClient64.dll?raw=true"
    $tempNvdaDll = Join-Path $env:TEMP "nvdaControllerClient64.dll"
    
    $downloadSuccess = Download-File -Url $nvdaControllerUrl -OutputPath $tempNvdaDll -MaxRetries 2
    if ($downloadSuccess) {
        Copy-Item -Path $tempNvdaDll -Destination $nvdaDllPath -Force
        Remove-Item $tempNvdaDll -Force -ErrorAction SilentlyContinue
        Write-Host "NVDA Controller Client downloaded and installed!" -ForegroundColor Green
        return $true
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

# Function to install the accessibility plugin
function Install-AccessibilityPlugin {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "Installing FM26 Accessibility Plugin..." -ForegroundColor Cyan
    
    $pluginsPath = Join-Path $GamePath "BepInEx\plugins"
    Write-Host "  [VERBOSE] Plugins directory: $pluginsPath" -ForegroundColor Gray
    
    if (-not (Test-Path $pluginsPath)) {
        Write-Host "  [VERBOSE] Creating plugins directory..." -ForegroundColor Gray
        New-Item -ItemType Directory -Path $pluginsPath -Force | Out-Null
    }
    
    # Get the directory where this script is located
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $sourcePluginPath = Join-Path (Split-Path -Parent $scriptDir) "build\FM26AccessibilityPlugin.dll"
    Write-Host "  [VERBOSE] Looking for plugin DLL at: $sourcePluginPath" -ForegroundColor Gray
    
    # Check if plugin DLL exists
    if (-not (Test-Path $sourcePluginPath)) {
        Write-Host "  [ERROR] Plugin DLL not found at: $sourcePluginPath" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Please build the plugin first using one of these methods:" -ForegroundColor Yellow
        Write-Host "    1. Run: dotnet build (from the repository root)" -ForegroundColor White
        Write-Host "    2. Run: .\build\build.ps1" -ForegroundColor White
        Write-Host "    3. Download a pre-built release from GitHub" -ForegroundColor White
        Write-Host ""
        Write-Host "  [VERBOSE] Listing contents of build directory:" -ForegroundColor Gray
        $buildDir = Join-Path (Split-Path -Parent $scriptDir) "build"
        if (Test-Path $buildDir) {
            Get-ChildItem -Path $buildDir -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "    $($_.Name)  ($($_.Length) bytes)" -ForegroundColor Gray
            }
        } else {
            Write-Host "    (build directory does not exist)" -ForegroundColor Gray
        }
        return $false
    }
    
    # Verify the DLL is valid
    $pluginSize = (Get-Item $sourcePluginPath).Length
    if ($pluginSize -eq 0) {
        Write-Host "  [ERROR] Plugin DLL is empty (0 bytes). It may be corrupted." -ForegroundColor Red
        return $false
    }
    
    Write-Host "  [VERBOSE] Plugin size: $([math]::Round($pluginSize / 1KB, 2)) KB" -ForegroundColor Gray
    
    # Copy plugin
    $destPluginPath = Join-Path $pluginsPath "FM26AccessibilityPlugin.dll"
    try {
        Write-Host "  [VERBOSE] Copying plugin to: $destPluginPath" -ForegroundColor Gray
        Copy-Item -Path $sourcePluginPath -Destination $destPluginPath -Force
        
        # Verify copy
        if (-not (Test-Path $destPluginPath)) {
            Write-Host "  [ERROR] Failed to copy plugin DLL to destination. File not found after copy." -ForegroundColor Red
            return $false
        }
        
        $destSize = (Get-Item $destPluginPath).Length
        Write-Host "  [VERBOSE] Verified copy: $([math]::Round($destSize / 1KB, 2)) KB at destination." -ForegroundColor Gray
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
    Write-Host "  [VERBOSE] Config directory: $configPath" -ForegroundColor Gray
    if (-not (Test-Path $configPath)) {
        Write-Host "  [VERBOSE] Creating config directory..." -ForegroundColor Gray
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
    Write-Host "  [VERBOSE] Writing config to: $configFile" -ForegroundColor Gray
    $pluginConfig | Out-File -FilePath $configFile -Encoding UTF8
    
    Write-Host "Configuration created!" -ForegroundColor Green
}

# Function to uninstall
function Uninstall-Mod {
    param([string]$GamePath)
    
    Write-Host ""
    Write-Host "Uninstalling $ModName..." -ForegroundColor Yellow
    
    $pluginPath = Join-Path $GamePath "BepInEx\plugins\FM26AccessibilityPlugin.dll"
    Write-Host "  [VERBOSE] Checking for plugin at: $pluginPath" -ForegroundColor Gray
    
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
    } else {
        Write-Host "  [VERBOSE] Using user-supplied FM26 path: $fm26Path" -ForegroundColor Gray
    }
    
    if ([string]::IsNullOrEmpty($fm26Path)) {
        Write-Host ""
        Write-Host "Could not find Football Manager 2026 installation automatically." -ForegroundColor Red
        Write-Host "Please enter the full path to your FM26 installation directory:" -ForegroundColor Yellow
        $fm26Path = Read-Host "FM26 Path"
        Write-Host "  [VERBOSE] User entered path: $fm26Path" -ForegroundColor Gray
        
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
    } else {
        $exeInfo = Get-Item $fmExe
        Write-Host "  [VERBOSE] fm.exe found: $([math]::Round($exeInfo.Length / 1MB, 2)) MB, last modified $($exeInfo.LastWriteTime)" -ForegroundColor Gray
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
