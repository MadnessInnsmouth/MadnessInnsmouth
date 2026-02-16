# FM26 Accessibility Mod - Library References

This directory contains reference DLLs needed to build the plugin.

## Required Libraries

### BepInEx and Harmony
BepInEx 6 and HarmonyX are consumed via **NuGet packages** from the BepInEx NuGet feed (configured in `NuGet.config`). No manual DLL downloads are needed for these.

### IL2CPP Interop Assemblies (lib/interop/)
Located in `lib/interop/`, these are generated from your FM26 installation using **Cpp2IL**:
- `Assembly-CSharp.dll`
- `UnityEngine.dll`
- `UnityEngine.UI.dll`
- `UnityEngine.CoreModule.dll`
- `UnityEngine.TextRenderingModule.dll`
- (and other interop assemblies as needed)

These are **not** raw Unity DLLs from `fm_Data/Managed/`. They are IL2CPP interop assemblies generated from `GameAssembly.dll` and `fm_Data/il2cpp_data/Metadata/global-metadata.dat` using Cpp2IL.

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
2. Install BepInEx 6 (IL2CPP) to your FM26 directory
3. Run the build script which will use Cpp2IL to generate interop assemblies into `lib/interop/`
4. Optionally add nvdaControllerClient64.dll for enhanced NVDA integration

## GitHub Actions

For CI/CD, these libraries are downloaded automatically during the build process.

## Note

Interop assemblies and the NVDA Controller Client DLL are not included in the repository due to licensing. You must generate the interop assemblies from your own FM26 installation using Cpp2IL.
