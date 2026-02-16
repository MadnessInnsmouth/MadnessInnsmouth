# Build Directory

This directory is intended to contain the pre-built `FM26AccessibilityPlugin.dll` file.

## For Users

If you downloaded this from the **source code** (Code → Download ZIP button), this directory will be empty.

**You need to download the pre-built release instead:**
1. Go to: https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases
2. Download the file named: `FM26-Accessibility-Mod-vX.X.X.zip`
3. Extract and run the installer

## For Developers

To build the plugin yourself:

1. **Install .NET SDK**: https://dotnet.microsoft.com/download

2. **Run the build script**:
   ```powershell
   .\build\build.ps1
   ```

3. The built DLL will be placed in this directory

## Why is this necessary?

The plugin requires:
- BepInEx libraries (downloaded by build script)
- Unity engine DLLs from Football Manager 2026

Without these dependencies, the plugin cannot be built. The build script will attempt to download BepInEx and locate FM26 automatically.

See [BUILD.md](../BUILD.md) for complete build instructions.
