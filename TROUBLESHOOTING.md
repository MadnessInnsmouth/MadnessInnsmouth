# Troubleshooting Guide - FM26 Accessibility Mod

This guide helps you diagnose and fix common issues with the FM26 Accessibility Mod.

## Quick Diagnostics

Before diving into specific issues, run this quick check:

### ✅ Pre-Flight Checklist

1. **Is FM26 installed?**
   - Check for `fm.exe` in the installation directory
   
2. **Is BepInEx installed?**
   - Look for `BepInEx` folder in FM26 directory
   - Check for `winhttp.dll` in FM26 root directory
   
3. **Is the plugin installed?**
   - Check for `BepInEx\plugins\FM26AccessibilityPlugin.dll`
   
4. **Is your screen reader running?**
   - Try speaking something in another app (e.g., Notepad)
   
5. **Check the logs:**
   - Open `BepInEx\LogOutput.log`
   - Look for recent entries (check timestamp)

---

## Installation Issues

### Downloaded Source Code Instead of Release

**Symptom**: Installer says "Plugin DLL not found" or "Please build the plugin first"

**Cause**: You downloaded the source code (for developers) instead of the pre-built release (for users).

**Solution**:

1. **Download the correct file**:
   - Go to: https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases
   - Download the file named: `FM26-Accessibility-Mod-vX.X.X.zip`
   - **NOT** the "Source code (zip)" or "Source code (tar.gz)" links

2. **How to identify the correct file**:
   - ✅ **Correct**: `FM26-Accessibility-Mod-v1.0.0.zip` (example)
   - ❌ **Wrong**: "Source code (zip)" - this is for developers only

3. **Why this matters**:
   - The pre-built release contains `FM26AccessibilityPlugin.dll` (ready to install)
   - The source code requires .NET SDK and building before it can be used
   - Most users want the pre-built release, not the source code

### Installer Can't Find FM26

**Symptom**: "Could not find Football Manager 2026 installation"

**Solutions**:

1. **Manual path entry**:
   ```powershell
   .\Install-FM26Accessibility.ps1 -FM26Path "C:\Your\Path\To\FM26"
   ```

2. **Check common locations**:
   - Steam: `C:\Program Files (x86)\Steam\steamapps\common\Football Manager 2026`
   - Game Pass: `C:\XboxGames\Football Manager 2026`
   - Epic: `C:\Program Files\Epic Games\Football Manager 2026`

3. **Find it yourself**:
   - Right-click FM26 in Steam → Manage → Browse Local Files
   - Copy the path shown in Explorer address bar

### PowerShell Script Won't Run

**Symptom**: "Script is not digitally signed" or execution blocked

**Solutions**:

1. **Allow this script once**:
   - Right-click `Install-FM26Accessibility.ps1`
   - Choose **"Run with PowerShell"**
   - Press **R** when prompted (Run once)

2. **Enable script execution** (permanent):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run as Administrator**:
   - Right-click PowerShell
   - Choose **"Run as Administrator"**
   - Navigate to installer directory
   - Run the script

### BepInEx Download Fails

**Symptom**: "Failed to download after 3 attempts"

**Solutions**:

1. **Check internet connection**:
   - Ensure you're connected
   - Try accessing https://github.com in a browser

2. **Check firewall**:
   - Temporarily disable firewall
   - Run installer again
   - Re-enable firewall

3. **Manual download**:
   - Visit: https://github.com/BepInEx/BepInEx/releases
   - Download `BepInEx_win_x64_5.4.23.2.zip`
   - Extract to FM26 directory manually

4. **Specify different version**:
   ```powershell
   .\Install-FM26Accessibility.ps1 -BepInExVersion "5.4.22"
   ```

### Plugin DLL Not Found

**Symptom**: "Plugin DLL not found at: build\FM26AccessibilityPlugin.dll"

**Solutions**:

1. **Build the plugin**:
   ```powershell
   dotnet build
   ```

2. **Or download pre-built release**:
   - Visit: https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases
   - Download latest release ZIP
   - Extract and run installer from there

3. **Check build directory**:
   - Ensure `build\FM26AccessibilityPlugin.dll` exists
   - If not, build failed - check for .NET SDK installation

---

## Runtime Issues

### Mod Not Loading

**Symptom**: FM26 starts normally but no accessibility features

**Diagnostic Steps**:

1. **Check BepInEx is active**:
   - Look for `BepInEx\LogOutput.log` after launching FM26
   - If file doesn't exist or isn't updated, BepInEx isn't loading

2. **Verify BepInEx setup**:
   - Check for `winhttp.dll` in FM26 root directory
   - Check for `doorstop_config.ini` in FM26 root directory

3. **Check logs**:
   - Open `BepInEx\LogOutput.log`
   - Search for: "FM26 Accessibility Plugin"
   - If not found, plugin didn't load

**Solutions**:

1. **Reinstall BepInEx**:
   ```powershell
   .\Install-FM26Accessibility.ps1 -Force
   ```

2. **Launch FM26 once to initialize BepInEx**:
   - Start FM26
   - Wait for main menu
   - Close FM26
   - This creates necessary config files
   - Try again

3. **Check for conflicts**:
   - Other mods in `BepInEx\plugins\` may conflict
   - Temporarily move them out
   - Test with only accessibility plugin

### Screen Reader Not Speaking

**Symptom**: Mod is loaded but nothing is announced

**Diagnostic Steps**:

1. **Test screen reader elsewhere**:
   - Open Notepad, type something
   - Screen reader should speak it
   - If not, screen reader isn't working

2. **Check logs for screen reader detection**:
   ```
   [Info   : FM26 Accessibility Plugin] Screen reader detected and active!
   ```
   Or:
   ```
   [Warning: FM26 Accessibility Plugin] No screen reader detected
   ```

3. **Check NVDA status** (if using NVDA):
   - Press **NVDA+T** to hear time
   - If nothing, NVDA isn't running

**Solutions**:

1. **Start screen reader BEFORE FM26**:
   - Close FM26 if running
   - Start your screen reader
   - Wait for it to fully load
   - Launch FM26

2. **Check app sleep mode** (NVDA):
   - In FM26, press **NVDA+Shift+S**
   - This toggles sleep mode for current app

3. **Enable SAPI fallback**:
   - Even without screen reader, SAPI should speak
   - Check Windows Sound settings
   - Ensure speakers/headphones are connected

4. **Increase logging**:
   - Edit: `BepInEx\config\com.accessibility.fm26.cfg`
   - Change: `EnableDebugLogging = true`
   - Restart FM26
   - Check logs for more details

### Announcements Are Delayed

**Symptom**: Screen reader speaks 2-3 seconds after selecting UI element

**Cause**: Update interval too slow or performance issues

**Solutions**:

1. **Decrease update interval**:
   - Edit: `BepInEx\config\com.accessibility.fm26.cfg`
   - Change: `UpdateInterval = 0.05` (faster, uses more CPU)
   - Default is `0.1`

2. **Check system performance**:
   - Open Task Manager
   - Look for high CPU/memory usage
   - Close unnecessary programs

3. **Lower FM26 graphics settings**:
   - In FM26, go to Preferences
   - Lower graphics quality
   - Disable unnecessary visual effects

### Duplicate Announcements

**Symptom**: Everything is said twice

**Cause**: Multiple speech methods active simultaneously

**Solutions**:

1. **Check logs**:
   ```
   [Info   : FM26 Accessibility Plugin] Spoke via NVDA Controller Client
   [Info   : FM26 Accessibility Plugin] Spoke via Windows SAPI
   ```
   If both appear, that's the issue

2. **Remove NVDA Controller Client** (temporary test):
   - Rename: `BepInEx\plugins\nvdaControllerClient64.dll.bak`
   - Restart FM26
   - If duplicate stops, report as bug

3. **Disable SAPI in NVDA**:
   - In NVDA: **NVDA+N** → **Preferences** → **Settings** → **Speech**
   - Change synthesizer from default if needed

### Nothing Happens When Pressing Tab

**Symptom**: Tab key does nothing in FM26

**Cause**: EventSystem not created or keyboard navigation disabled

**Solutions**:

1. **Check logs**:
   - Look for: "Created EventSystem for UI navigation"
   - If not found, Harmony patches may have failed

2. **Verify configuration**:
   - Edit: `BepInEx\config\com.accessibility.fm26.cfg`
   - Ensure: `EnableKeyboardNav = true`

3. **Try arrow keys**:
   - Some UI may respond to arrows instead of Tab
   - Try all four arrow keys

4. **Check for UI-specific issues**:
   - Tab may work in some screens but not others
   - Report which screens don't work

---

## Performance Issues

### FM26 Runs Slowly

**Symptom**: Game is laggy or stuttering with mod installed

**Solutions**:

1. **Increase update interval**:
   - Edit: `BepInEx\config\com.accessibility.fm26.cfg`
   - Change: `UpdateInterval = 0.2` (slower updates, less CPU)

2. **Disable debug logging**:
   - Edit: `BepInEx\config\com.accessibility.fm26.cfg`
   - Ensure: `EnableDebugLogging = false`

3. **Check system resources**:
   - Task Manager → Performance tab
   - If CPU/RAM maxed out, close other apps

4. **Update graphics drivers**:
   - Check for latest drivers from GPU manufacturer

### High CPU Usage

**Symptom**: CPU usage very high when FM26 with mod is running

**Solutions**:

1. **Check logs for errors**:
   - Repeating errors can cause CPU spikes
   - Fix underlying issue

2. **Increase update interval** (see above)

3. **Report as bug** with logs if issue persists

---

## NVDA-Specific Issues

### NVDA Controller Client Not Working

**Symptom**: Logs say "NVDA Controller Client is not available"

**Expected**: This is normal if you don't have the DLL

**To enable**:

1. **Install NVDA Controller Client**:
   - See [NVDA_SETUP.md](NVDA_SETUP.md) for instructions
   - Place `nvdaControllerClient64.dll` in `BepInEx\plugins\`
   - Restart FM26

2. **Verify**:
   - Check logs for: "NVDA Controller Client is available and NVDA is running!"

**Note**: Mod works fine without it - just uses SAPI instead

### NVDA Speaks FM26 Elements Incorrectly

**Symptom**: NVDA says generic names like "GameObject" instead of button labels

**Cause**: UI elements may not have accessible labels

**Solutions**:

1. **Use virtual menu mode**:
   - In FM26, press **NVDA+Space** to enter browse mode
   - Try navigating with browse mode keys

2. **Report as bug**:
   - Note which UI elements are affected
   - Include screenshot if possible
   - Report on GitHub with details

---

## Error Messages

### "Failed to initialize plugin"

**In logs**: `[Error  : FM26 Accessibility Plugin] Failed to initialize plugin: ...`

**Solutions**:

1. **Check full error message** for specifics
2. **Common causes**:
   - Missing dependencies (.NET Framework)
   - Corrupted DLL files
   - Incompatible FM26 version
3. **Reinstall mod** with `-Force` flag

### "Error in Update"

**In logs**: `[Error  : FM26 Accessibility Plugin] Error in Update: ...`

**Solutions**:

1. **Usually harmless** - single error is okay
2. **If repeating**:
   - Note exact error message
   - Report as bug
   - May need to disable mod temporarily

### "Harmony patches failed"

**In logs**: `[Error  : FM26 Accessibility Plugin] Failed to apply Harmony patches: ...`

**Solutions**:

1. **Update BepInEx**:
   ```powershell
   .\Install-FM26Accessibility.ps1 -Force -BepInExVersion "5.4.23.2"
   ```

2. **Check for mod conflicts**:
   - Other mods may interfere with Harmony
   - Test with only accessibility mod

3. **Report as bug** with full error details

---

## Log Analysis

### How to Read Logs

Logs are in: `BepInEx\LogOutput.log`

**Important lines to look for**:

✅ **Success indicators**:
```
[Info   : BepInEx] Chainloader started
[Info   : FM26 Accessibility Plugin] Plugin loaded!
[Info   : FM26 Accessibility Plugin] Harmony patches applied successfully!
[Info   : FM26 Accessibility Plugin] FM26 Accessibility Plugin initialized successfully!
[Info   : FM26 Accessibility Plugin] NVDA Controller Client is available
```

❌ **Error indicators**:
```
[Error  : FM26 Accessibility Plugin] Failed to initialize
[Error  : FM26 Accessibility Plugin] Error in Update
[Error  : FM26 Accessibility Plugin] Could not load
```

⚠️ **Warnings (may be okay)**:
```
[Warning: FM26 Accessibility Plugin] No screen reader detected
[Warning: FM26 Accessibility Plugin] NVDA Controller Client not available
```

### Collecting Logs for Bug Reports

When reporting issues, include:

1. **Last 50-100 lines** of `BepInEx\LogOutput.log`
2. **Time the issue occurred**
3. **What you were doing** when it happened
4. **Your system info**:
   - Windows version
   - FM26 version
   - Screen reader and version
   - Mod version

---

## Still Need Help?

If this guide doesn't solve your issue:

1. **Check GitHub Issues**:
   - https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues
   - Someone may have reported the same problem

2. **Open a new issue**:
   - Provide all diagnostic information
   - Include relevant log excerpts
   - Describe what you've tried

3. **Community Discussion**:
   - https://github.com/MadnessInnsmouth/MadnessInnsmouth/discussions
   - Ask for help from the community

---

## Emergency: Uninstalling

If the mod is causing serious issues:

### Quick Uninstall

```powershell
.\Install-FM26Accessibility.ps1 -Uninstall
```

### Manual Uninstall

1. Delete: `BepInEx\plugins\FM26AccessibilityPlugin.dll`
2. Delete: `BepInEx\plugins\nvdaControllerClient64.dll` (if present)
3. FM26 will work normally without the mod

### Remove BepInEx Completely

1. Delete the entire `BepInEx` folder from FM26 directory
2. Delete: `winhttp.dll` from FM26 root
3. Delete: `doorstop_config.ini` from FM26 root
4. Verify game files through Steam/Game Pass

---

**Last updated**: 2026-02-15
