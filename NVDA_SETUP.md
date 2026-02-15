# NVDA Setup Guide for FM26 Accessibility Mod

This guide helps you set up NVDA (NonVisual Desktop Access) with the FM26 Accessibility Mod for the best experience.

## What is NVDA?

NVDA is a free, open-source screen reader for Windows. It's the recommended screen reader for this mod because:
- ✅ **Free and Open Source** - No cost, ever
- ✅ **Excellent Gaming Support** - Works well with Unity games
- ✅ **Active Development** - Regular updates and improvements
- ✅ **Direct Integration** - This mod can communicate directly with NVDA

## Installing NVDA

### Step 1: Download NVDA

1. Visit: https://www.nvaccess.org/download/
2. Click **"Download"**
3. Choose either:
   - **Installer** (Recommended) - Installs NVDA permanently
   - **Portable** - Run from a USB drive or folder

### Step 2: Install NVDA

1. Run the installer you downloaded
2. Follow the installation wizard
3. Choose your preferences:
   - **Keyboard Layout**: Desktop or Laptop
   - **Caps Lock as NVDA key**: Recommended for beginners
4. Click **Install**

### Step 3: Start NVDA

- NVDA should start automatically after installation
- To start manually: Press **Windows+Ctrl+N**
- Or: Find "NVDA" in your Start Menu

## Basic NVDA Controls

Once NVDA is running, learn these essential keys:

| Key | Function |
|-----|----------|
| **NVDA+Q** | Quit NVDA |
| **NVDA+S** | Toggle speech mode (on/off/beeps) |
| **NVDA+Shift+S** | Toggle sleep mode for current app |
| **Control** | Stop speaking |
| **NVDA+1** | Toggle input help (learn keys) |

> **Note**: NVDA key is either **Insert** or **Caps Lock** depending on your setup

## Configuring NVDA for FM26

### Recommended Settings

1. **Open NVDA Settings**:
   - Press **NVDA+N** to open NVDA menu
   - Navigate to **Preferences** → **Settings**

2. **Speech Settings**:
   - **Rate**: Start at 40-50 (adjust to your preference)
   - **Pitch**: 50 (default)
   - **Volume**: 80-100
   - Enable: **"Automatic language switching"** (if available)

3. **Keyboard Settings**:
   - Enable: **"Speak typed characters"**
   - Enable: **"Speak typed words"**
   - Enable: **"Speak command keys"**

4. **Object Presentation**:
   - Enable: **"Report object descriptions"**
   - Enable: **"Report tool tips"**
   - Enable: **"Report help balloons"**

### Advanced: Optimizing for Gaming

For the best gaming experience with FM26:

1. **Disable unnecessary features**:
   - **NVDA+N** → **Preferences** → **Settings** → **Browse Mode**
   - Uncheck: **"Automatic focus mode for focus changes"** (optional)

2. **Adjust verbosity**:
   - **NVDA+V** cycles through verbosity levels
   - For gaming, use a lower verbosity level

3. **Create a profile for FM26** (Advanced):
   - **NVDA+N** → **Configuration profiles**
   - Create a new profile triggered by "fm.exe"
   - Customize settings specifically for FM26

## Using NVDA with FM26

### First Launch

1. **Start NVDA** (Windows+Ctrl+N)
2. **Wait for NVDA to fully load** (you'll hear a chime)
3. **Launch Football Manager 2026**
4. **Wait 5-10 seconds** for the mod to initialize
5. **Press Tab** - You should hear menu items

### Expected Behavior

When working correctly:
- ✅ **Menu items are announced** when you Tab through them
- ✅ **Button names are spoken** clearly
- ✅ **Checkbox states** (checked/unchecked) are reported
- ✅ **Text fields** announce their labels and values
- ✅ **Focus changes** are announced immediately

### If NVDA Isn't Speaking

1. **Check NVDA is running**:
   - Press **NVDA+T** to hear time (confirms NVDA works)
   
2. **Check FM26 is not in sleep mode**:
   - Press **NVDA+Shift+S** to wake FM26
   
3. **Check logs**:
   - Open: `<FM26_Directory>\BepInEx\LogOutput.log`
   - Look for: "NVDA Controller Client is available"
   
4. **Try restarting**:
   - Close FM26
   - Restart NVDA (NVDA+Q, then Windows+Ctrl+N)
   - Launch FM26 again

## NVDA Controller Client (Enhanced Integration)

The mod supports **direct NVDA integration** via the NVDA Controller Client, which provides:
- ✅ Faster response times
- ✅ Better synchronization
- ✅ More reliable announcements

### Installation

The installer will attempt to include this automatically. If not:

1. **Check if installed**:
   - Look for: `<FM26_Directory>\BepInEx\plugins\nvdaControllerClient64.dll`

2. **Manual installation**:
   - Download from: https://www.nvaccess.org/files/nvda/releases/stable/
   - Place `nvdaControllerClient64.dll` in `BepInEx\plugins\`
   - Restart FM26

3. **Verify**:
   - Check `BepInEx\LogOutput.log`
   - Should see: "NVDA Controller Client is available and NVDA is running!"

### Without NVDA Controller Client

Don't worry if you can't get the Controller Client! The mod will:
- ✅ **Automatically fall back** to Windows SAPI
- ✅ **Still work** with NVDA (NVDA listens to system audio)
- ✅ **Provide all features** with slightly slower response

## Troubleshooting

### NVDA Announces Too Much

**Solution**: Lower verbosity
- Press **NVDA+V** repeatedly until comfortable

### NVDA Speaks Too Fast

**Solution**: Adjust speech rate
- **NVDA+Ctrl+Up/Down Arrow** - Adjust rate on the fly
- Or: **NVDA+N** → **Preferences** → **Settings** → **Speech**

### NVDA Doesn't Hear FM26

**Symptom**: NVDA works everywhere except FM26

**Solutions**:
1. **Check sleep mode**: Press **NVDA+Shift+S** in FM26
2. **Reinstall mod**: Run installer with `-Force` flag
3. **Check Windows version**: Ensure Windows 10/11 (64-bit)
4. **Verify .NET Framework**: Install .NET Framework 4.8

### Announcements Are Choppy

**Solutions**:
1. **Reduce update frequency**:
   - Edit: `BepInEx\config\com.accessibility.fm26.cfg`
   - Change: `UpdateInterval = 0.2` (slower but more stable)
2. **Lower graphics settings** in FM26
3. **Close other programs** using screen reader

### Duplicate Announcements

**Symptom**: Everything is said twice

**Cause**: Both NVDA Controller Client and SAPI are active

**Solution**:
1. Check logs to see which method is being used
2. If both active, remove `nvdaControllerClient64.dll` temporarily
3. Report as bug if issue persists

## Best Practices

### For the Best Experience

1. ✅ **Start NVDA before FM26** - Always launch screen reader first
2. ✅ **Wait for initialization** - Give mod 5-10 seconds to start
3. ✅ **Use Tab for navigation** - Most reliable method
4. ✅ **Save frequently** - Use Ctrl+S to save often
5. ✅ **Check logs when stuck** - `BepInEx\LogOutput.log` has details

### Keyboard Shortcuts Summary

**In FM26 (with mod)**:
- **Tab** / **Shift+Tab** - Navigate UI elements
- **Arrow Keys** - Navigate lists and menus
- **Enter** - Activate/Select
- **Space** - Toggle checkboxes
- **Escape** - Go back/Cancel

**NVDA Controls**:
- **NVDA+Q** - Quit NVDA
- **Control** - Stop speaking
- **NVDA+V** - Adjust verbosity
- **NVDA+Ctrl+Up/Down** - Adjust speech rate

## Getting Help

### Check Logs

Always check logs first:
```
<FM26_Directory>\BepInEx\LogOutput.log
```

Look for:
- ✅ "FM26 Accessibility Plugin initialized successfully!"
- ✅ "NVDA Controller Client is available and NVDA is running!"
- ❌ Any error messages

### Report Issues

If you find a bug:

1. **Gather information**:
   - Your Windows version
   - Your NVDA version (NVDA+H for help, shows version)
   - Last 50 lines of `BepInEx\LogOutput.log`
   - What you were doing when it failed

2. **Report on GitHub**:
   - Visit: https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues
   - Click **New Issue**
   - Choose **Bug Report**
   - Include all information from step 1

### Community

- **GitHub Discussions**: https://github.com/MadnessInnsmouth/MadnessInnsmouth/discussions
- **NVDA Community**: https://nvda.groups.io/g/nvda

## Additional Resources

### Learning NVDA

- **Official Guide**: https://www.nvaccess.org/files/nvda/documentation/userGuide.html
- **NVDA Training**: https://www.nvaccess.org/get-help/
- **YouTube Tutorials**: Search "NVDA screen reader tutorial"

### Accessibility Gaming

- **Audio Game Archive**: https://audiogames.net/
- **Gaming for the Blind**: https://www.g4b.org/
- **Accessible Gaming**: https://accessible.games/

---

## Quick Reference Card

### Essential NVDA Keys
```
NVDA+Q              Quit NVDA
NVDA+S              Speech mode toggle
NVDA+Shift+S        App sleep mode
Control             Stop speaking
NVDA+T              Read time
NVDA+V              Verbosity
NVDA+Ctrl+↑/↓       Speech rate
```

### FM26 Navigation
```
Tab / Shift+Tab     Next/Previous element
Arrow Keys          Navigate within menus
Enter               Activate/Select
Space               Toggle checkboxes
Escape              Go back/Cancel
```

### Troubleshooting
```
1. NVDA+T           Test if NVDA works
2. NVDA+Shift+S     Wake app from sleep
3. Check logs       BepInEx\LogOutput.log
4. Restart both     Close FM26 and NVDA
```

---

**Need more help?** Check the [main README](README.md) or [open an issue](https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues).
