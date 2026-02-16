# FM26 Accessibility Plugin - Build Instructions

## ⚠️ Do You Need to Build from Source?

**Most users DON'T need to build from source!**

### You DON'T need to build if:
- ✅ You just want to use the mod
- ✅ You downloaded from the Releases page
- ✅ You just want to play FM26 with accessibility features

→ **Just download the pre-built release and run the installer!**

### You DO need to build if:
- 🔧 You're contributing code changes
- 🔧 You're testing unreleased features
- 🔧 You're a developer wanting to modify the mod
- 🔧 There's no pre-built release available yet

---

## Building the Plugin

This plugin requires BepInEx libraries to build. Since these are not available on standard NuGet feeds, you have two options:

### Option 1: Use Pre-Built Release

Download the latest pre-built release from the [Releases page](https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases).

### Option 2: Build from Source

#### Prerequisites

1. **Visual Studio 2019 or later** (Community edition is free)
   - Install .NET desktop development workload
   - Install .NET Framework 4.8 SDK

2. **BepInEx Dev Pack**
   - Download BepInEx from: https://github.com/BepInEx/BepInEx/releases
   - Extract and locate these DLLs:
     - `BepInEx/core/BepInEx.dll`
     - `BepInEx/core/0Harmony.dll`
   
3. **Unity Engine DLLs**
   - These are included with Football Manager 2026
   - Located in: `<FM26_Install>/fm_Data/Managed/`
   - You need:
     - `UnityEngine.dll`
     - `UnityEngine.UI.dll`
     - `UnityEngine.CoreModule.dll`

#### Build Steps

1. **Setup Reference Libraries**
   ```bash
   mkdir -p lib
   # Copy BepInEx DLLs to lib/
   # Copy Unity DLLs to lib/
   ```

2. **Update Project References**
   - The project file needs to reference these local DLLs
   - See `FM26AccessibilityPlugin.csproj` for reference paths

3. **Build**
   ```bash
   dotnet build src/FM26AccessibilityPlugin/FM26AccessibilityPlugin.csproj --configuration Release
   ```

4. **Output**
   - Built DLL will be in: `src/FM26AccessibilityPlugin/bin/Release/net48/FM26AccessibilityPlugin.dll`

## Alternative: Use Included Build Script

For convenience, we've included a build script that handles everything:

### Windows (PowerShell)
```powershell
.\build\build.ps1
```

This script will:
1. Check for required dependencies
2. Download BepInEx if needed
3. Locate FM26 installation for Unity DLLs
4. Build the plugin
5. Create a release package

## After Building

Once built, use the installer to deploy:
```powershell
.\install\Install-FM26Accessibility.ps1
```

## Development Setup

For active development:

1. Set `FM26_PATH` environment variable to your FM26 installation
2. The build will automatically copy the plugin to the game directory
3. Run FM26 to test changes

## Troubleshooting

### Missing References

If you get missing reference errors:
- Ensure BepInEx is installed in your FM26 directory
- Copy required DLLs to the `lib/` folder
- Update reference paths in the `.csproj` file

### Build Fails

- Check that .NET Framework 4.8 SDK is installed
- Verify all reference DLLs are present
- Try cleaning: `dotnet clean` then rebuild

## CI/CD

GitHub Actions automatically builds the plugin on push. See `.github/workflows/build.yml` for the workflow configuration.
