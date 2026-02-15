# FM26 Accessibility Mod Installer
# This script automatically installs the FM26 accessibility mod and all dependencies

param(
    [string]$FM26Path = "",
    [switch]$Uninstall = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Script configuration
$ModName = "FM26 Accessibility Mod"
$ModVersion = "1.0.0"
$BepInExVersion = "5.4.23.2"
$BepInExDownloadUrl = "https://github.com/BepInEx/BepInEx/releases/download/v$BepInExVersion/BepInEx_win_x64_$BepInExVersion.0.zip"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  $ModName Installer v$ModVersion" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
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
    } catch {}
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $exePath = Join-Path $path "fm.exe"
            if (Test-Path $exePath) {
                Write-Host "Found FM26 at: $path" -ForegroundColor Green
                return $path
            }
        }
    }
    
    return $null
}

# Function to download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    Write-Host "Downloading from: $Url" -ForegroundColor Yellow
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        Write-Host "Download complete!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to extract zip file
function Extract-ZipFile {
    param(
        [string]$ZipPath,
        [string]$DestPath
    )
    
    Write-Host "Extracting to: $DestPath" -ForegroundColor Yellow
    
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $DestPath)
        Write-Host "Extraction complete!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Extraction failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to install BepInEx
function Install-BepInEx {
    param([string]$GamePath)
    
    $bepInExPath = Join-Path $GamePath "BepInEx"
    
    if ((Test-Path $bepInExPath) -and -not $Force) {
        Write-Host "BepInEx is already installed." -ForegroundColor Green
        return $true
    }
    
    Write-Host ""
    Write-Host "Installing BepInEx $BepInExVersion..." -ForegroundColor Cyan
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "FM26Mod_Temp"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Download BepInEx
    $zipPath = Join-Path $tempDir "BepInEx.zip"
    Write-Host "Downloading BepInEx..."
    if (-not (Download-File -Url $BepInExDownloadUrl -OutputPath $zipPath)) {
        return $false
    }
    
    # Extract BepInEx
    Write-Host "Installing BepInEx to game directory..."
    if (-not (Extract-ZipFile -ZipPath $zipPath -DestPath $GamePath)) {
        return $false
    }
    
    # Clean up
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "BepInEx installed successfully!" -ForegroundColor Green
    return $true
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
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $sourcePluginPath = Join-Path (Split-Path -Parent $scriptDir) "build\FM26AccessibilityPlugin.dll"
    
    # Check if plugin DLL exists
    if (-not (Test-Path $sourcePluginPath)) {
        Write-Host "Plugin DLL not found at: $sourcePluginPath" -ForegroundColor Yellow
        Write-Host "Attempting to download pre-built version..." -ForegroundColor Yellow
        
        # For now, create a placeholder message
        Write-Host "Please build the plugin using: dotnet build" -ForegroundColor Red
        return $false
    }
    
    # Copy plugin
    $destPluginPath = Join-Path $pluginsPath "FM26AccessibilityPlugin.dll"
    Copy-Item -Path $sourcePluginPath -Destination $destPluginPath -Force
    
    Write-Host "Accessibility plugin installed!" -ForegroundColor Green
    return $true
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
    }
    
    Write-Host "Uninstall complete!" -ForegroundColor Green
    Write-Host "Note: BepInEx framework was not removed. Remove manually if desired." -ForegroundColor Yellow
}

# Main installation flow
function Main {
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "WARNING: Not running as administrator. Installation may fail." -ForegroundColor Yellow
        $response = Read-Host "Continue anyway? (y/n)"
        if ($response -ne 'y') {
            exit 1
        }
    }
    
    # Find FM26 installation
    $fm26Path = $FM26Path
    if ([string]::IsNullOrEmpty($fm26Path)) {
        $fm26Path = Find-FM26Installation
    }
    
    if ([string]::IsNullOrEmpty($fm26Path)) {
        Write-Host ""
        Write-Host "Could not find Football Manager 2026 installation." -ForegroundColor Red
        Write-Host "Please enter the path manually:" -ForegroundColor Yellow
        $fm26Path = Read-Host "FM26 Path"
        
        if (-not (Test-Path $fm26Path)) {
            Write-Host "Invalid path. Exiting." -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "Installation Path: $fm26Path" -ForegroundColor Cyan
    Write-Host ""
    
    # Uninstall mode
    if ($Uninstall) {
        Uninstall-Mod -GamePath $fm26Path
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
    
    # Install BepInEx
    if (-not (Install-BepInEx -GamePath $fm26Path)) {
        Write-Host ""
        Write-Host "Installation failed at BepInEx stage." -ForegroundColor Red
        exit 1
    }
    
    # Install plugin
    if (-not (Install-AccessibilityPlugin -GamePath $fm26Path)) {
        Write-Host ""
        Write-Host "Installation failed at plugin stage." -ForegroundColor Red
        Write-Host "You can still use BepInEx with other mods." -ForegroundColor Yellow
        exit 1
    }
    
    # Create configuration
    Create-Configuration -GamePath $fm26Path
    
    # Success message
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Installation Complete!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "The FM26 Accessibility Mod has been installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Launch Football Manager 2026" -ForegroundColor White
    Write-Host "2. Ensure your screen reader (NVDA, JAWS, or Narrator) is running" -ForegroundColor White
    Write-Host "3. Navigate menus using Tab and Arrow keys" -ForegroundColor White
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
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
