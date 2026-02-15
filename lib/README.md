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

## Setup Instructions

1. Install Football Manager 2026
2. Install BepInEx to your FM26 directory
3. Run the build script which will automatically copy these files here

## GitHub Actions

For CI/CD, these libraries are downloaded automatically during the build process.

## Note

These DLLs are not included in the repository due to licensing. You must obtain them from the original sources.
