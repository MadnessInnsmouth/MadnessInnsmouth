# FM26 Accessibility Mod - Library References

This directory should contain reference DLLs needed to build the plugin:

## Required Libraries

### From BepInEx (Download from https://github.com/BepInEx/BepInEx/releases)
- `BepInEx.dll` - Core BepInEx framework
- `0Harmony.dll` - Harmony patching library

### From Football Manager 2026 Installation
Located in `<FM26_Install>/fm_Data/Managed/`:
- `UnityEngine.dll`
- `UnityEngine.UI.dll`
- `UnityEngine.CoreModule.dll`
- `UnityEngine.TextRenderingModule.dll`

### NVDA Controller Client (Optional for Enhanced NVDA Support)
- `nvdaControllerClient64.dll` - NVDA Controller Client for direct NVDA communication

**How to Obtain:**
1. **Download from NVDA website:**
   - Visit: https://www.nvaccess.org/files/nvda/releases/stable/
   - Download the latest NVDA Controller Client package
   - Extract `nvdaControllerClient64.dll`
   - Place it in this `lib` directory

2. **Or extract from NVDA installation:**
   - If NVDA is installed, the DLL can be found in the NVDA installation directory
   - Typically: `C:\Program Files (x86)\NVDA\lib64\nvdaControllerClient64.dll`
   - Copy it to this `lib` directory

**Why It's Not Included:**
The NVDA Controller Client is licensed separately and must be obtained from official NVDA sources.

**What If I Don't Have It?**
The mod will still work! If not available, the plugin falls back to Windows SAPI.

## Setup Instructions

1. Install Football Manager 2026
2. Install BepInEx to your FM26 directory
3. Run the build script which will automatically copy these files here
4. Optionally add nvdaControllerClient64.dll for enhanced NVDA integration

## GitHub Actions

For CI/CD, these libraries are downloaded automatically during the build process.

## Note

These DLLs are not included in the repository due to licensing. You must obtain them from the original sources.
