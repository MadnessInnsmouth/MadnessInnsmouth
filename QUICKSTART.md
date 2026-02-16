# Quick Start Guide - FM26 Accessibility Mod

This guide will help you install and use the FM26 Accessibility Mod in just a few minutes.

## Prerequisites

Before you start, make sure you have:

1. ✅ **Football Manager 2026** installed (Steam or Xbox Game Pass version)
2. ✅ **Windows 10/11** (64-bit)
3. ✅ **Screen Reader** installed and working:
   - **NVDA** (Recommended - Free): https://www.nvaccess.org/download/ - See [NVDA_SETUP.md](NVDA_SETUP.md) for complete setup guide
   - **JAWS**: https://www.freedomscientific.com/products/software/jaws/
   - **Windows Narrator**: Built into Windows (Press Windows+Ctrl+Enter)

## Installation (3 Simple Steps)

### Step 1: Download the Mod

1. Go to the [Releases page](https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases)
2. Download the latest `FM26-Accessibility-Mod-vX.X.X.zip` file
3. Extract the ZIP file to a folder (e.g., `C:\FM26Mod\`)

**Important Note:** Due to Unity licensing restrictions, pre-built plugin DLLs are not included in releases. The installer will automatically build the plugin for you using the Unity assemblies from your FM26 installation. This requires:
- **.NET 6.0 SDK** installed (download from https://dotnet.microsoft.com/download)
- Internet connection (to download BepInEx)

### Step 2: Run the Installer

1. **Double-click** `Install-FM26Accessibility.bat` to launch the installer
2. If you see a security warning, click **"Run anyway"**
3. The installer will proceed automatically — administrator privileges are not required
4. Follow the on-screen instructions
5. The installer will:
   - Find your FM26 installation automatically
   - Download BepInEx 6 (the modding framework for IL2CPP)
   - **Build the accessibility plugin** (if not already built)
   - Install the accessibility plugin
   - Configure everything for you

**Note:** The first-time installation may take a few minutes while the plugin is built.

### Step 3: Launch the Game

1. **Start your screen reader** (if not already running)
2. Launch **Football Manager 2026**
3. Wait a few seconds for the mod to load
4. Navigate the main menu with **Tab** and **Arrow keys**

## First Time Use

### Testing It Works

1. Launch FM26
2. Your screen reader should announce: "Football Manager 2026"
3. Press **Tab** - you should hear menu items being read
4. Press **Enter** to select an item

### Keyboard Controls

| Key | Action |
|-----|--------|
| **Tab** | Move to next UI element |
| **Shift+Tab** | Move to previous element |
| **Arrow Keys** | Navigate within menus/lists |
| **Enter** | Select/Activate |
| **Escape** | Go back/Cancel |
| **Space** | Toggle checkboxes |

## Troubleshooting

### "Plugin DLL not found" or "Build failed"

This happens when the installer cannot automatically build the plugin. Solutions:

1. **Install .NET SDK** (if not already installed):
   - Download from: https://dotnet.microsoft.com/download
   - Install the latest .NET 6.0 SDK (or higher)
   - Restart your PowerShell/Command Prompt
   - Run the installer again

2. **Manual Build**:
   ```powershell
   # From the extracted mod folder:
   cd build
   .\build.ps1 -FM26Path "C:\Path\To\Your\FM26"
   ```
   Then run the installer again.

3. **Clone and Build from Repository** (alternative):
   ```powershell
   git clone https://github.com/MadnessInnsmouth/MadnessInnsmouth.git
   cd MadnessInnsmouth
   .\build\build.ps1
   .\install\Install-FM26Accessibility.ps1
   ```

**Why this happens:** The plugin needs to reference IL2CPP interop assemblies generated from your FM26 installation. These cannot be legally redistributed in pre-built releases, so the plugin must be built locally using interop assemblies generated from your game's files.

### "Nothing is being read"

1. Make sure your screen reader is running **BEFORE** you launch FM26
2. Try restarting FM26
3. Check the BepInEx log file at:
   ```
   <FM26_Directory>\BepInEx\LogOutput.log
   ```
4. Look for lines mentioning "FM26 Accessibility Plugin"

### "Installer can't find FM26"

1. When prompted, manually enter the path to your FM26 installation
2. Common paths:
   - Steam: `C:\Program Files (x86)\Steam\steamapps\common\Football Manager 2026`
   - Xbox: `C:\XboxGames\Football Manager 2026`

### "Installer won't run"

The `.bat` launcher handles PowerShell execution policy automatically. If you still have issues:

1. Make sure both `Install-FM26Accessibility.bat` and `Install-FM26Accessibility.ps1` are in the same folder
2. Right-click the `.bat` file and select **"Run as administrator"**
3. If Windows SmartScreen blocks it, click **"More info"** → **"Run anyway"**

### "Mod doesn't load after installation"

1. Launch FM26 once, then close it (this creates BepInEx config files)
2. Check that `BepInEx\plugins\FM26AccessibilityPlugin.dll` exists
3. Try reinstalling by running the installer again with `-Force` flag:
   ```powershell
   .\Install-FM26Accessibility.ps1 -Force
   ```

## Getting Help

### Check the Logs

The mod creates detailed logs here:
```
<FM26_Directory>\BepInEx\LogOutput.log
```

Look for:
- `FM26 Accessibility Plugin initialized successfully!` ✅ Good!
- Any error messages ❌ Something went wrong

### Comprehensive Guides

- **[NVDA_SETUP.md](NVDA_SETUP.md)** - Complete NVDA setup, configuration, and optimization
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Detailed troubleshooting for all common issues

### Report Issues

If you're still having problems:

1. Go to: https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues
2. Click "New Issue"
3. Include:
   - Your Windows version
   - Your screen reader (NVDA, JAWS, etc.)
   - The error message or problem
   - Contents of `BepInEx\LogOutput.log` (last 50 lines)

## Uninstalling

To remove the mod:

1. Run: `.\Install-FM26Accessibility.ps1 -Uninstall`
2. Or manually delete: `<FM26_Directory>\BepInEx\plugins\FM26AccessibilityPlugin.dll`

Note: This keeps BepInEx installed (in case you use other mods). To completely remove BepInEx, delete the `BepInEx` folder from your FM26 directory.

## What's Next?

- Check out the full [README](README.md) for advanced features
- Join the community discussions
- Report bugs or request features on GitHub

## Tips for Best Experience

1. **Use NVDA**: It's free and works great with this mod
2. **Reduce speech rate**: Start slower while learning the interface
3. **Use headphones**: Easier to focus on screen reader output
4. **Be patient**: First load can take a few seconds
5. **Save often**: While the mod is stable, it's always good practice

---

**Need more help?** Check the [full documentation](README.md) or [open an issue](https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues).
