# Changelog

All notable changes to the FM26 Accessibility Mod will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **IL2CPP Migration**: Migrated from BepInEx 5 (Mono) to BepInEx 6 (IL2CPP Bleeding Edge)
- **Cpp2IL Integration**: Interop assemblies now generated from `GameAssembly.dll` and `global-metadata.dat` via Cpp2IL
- **NuGet Package References**: BepInEx and HarmonyX consumed via NuGet packages from BepInEx feed
- **IL2CPP MonoBehaviour Support**: Added `IntPtr` constructors and `ClassInjector.RegisterTypeInIl2Cpp<T>()` for all MonoBehaviour types

### Changed
- **Target Framework**: Migrated from .NET Framework 4.8 (net48) to .NET 6.0 (net6.0)
- **Plugin Base Class**: Changed from `BaseUnityPlugin` to `BasePlugin` for BepInEx 6 IL2CPP compatibility
- **Interop Assemblies**: Unity DLLs from `fm_Data/Managed/` replaced with IL2CPP interop assemblies in `lib/interop/`
- **Build Output Path**: Changed from `bin/Release/net48/` to `bin/Release/net6.0/`
- **BepInEx Download**: Updated from `BepInEx_win_x64_5.4.23.2.zip` to `BepInEx-Unity.IL2CPP-win-x64-6.0.0-pre.2.zip`
- **Dependency Management**: Replaced local `BepInEx.dll`/`0Harmony.dll` references with NuGet packages

### Removed
- **Manual BepInEx DLLs**: No longer need to manually download `BepInEx.dll` and `0Harmony.dll` to `lib/`

### Documentation
- Updated all documentation to reflect IL2CPP migration

### Added
- **Direct NVDA Integration**: Added NVDA Controller Client P/Invoke wrapper for direct NVDA communication
- **Enhanced Screen Reader Detection**: Multi-level screen reader detection and fallback mechanism
- **Robust Installer**: Added retry logic, file validation, and better error handling to installer
- **BepInEx Version Control**: Installer now accepts `-BepInExVersion` parameter for flexibility
- **NVDA Controller Client Support**: Installer attempts to install NVDA Controller Client DLL
- **Component Verification**: Installer verifies all components after installation
- **Comprehensive Documentation**: Added NVDA_SETUP.md and TROUBLESHOOTING.md guides
- **Enhanced Logging**: Better status reporting for screen reader availability
- **Graceful Degradation**: Improved fallback from NVDA Controller Client to SAPI

### Changed
- **Screen Reader Interface**: Completely rewritten with multi-tier fallback (NVDA → SAPI → Silent)
- **Null Safety**: Added comprehensive null checks in UI tracking
- **TextMeshPro Handling**: Wrapped TextMeshPro calls in try-catch for better compatibility
- **Download Function**: Enhanced with retry logic and file size validation
- **Extract Function**: Added validation for zip file integrity
- **Plugin Installation**: Added DLL size verification and better error messages

### Fixed
- **EventSystem Null Check**: Fixed potential null reference exception when EventSystem not available
- **SAPI Initialization**: Properly initializes and stores SAPI synthesizer for reuse
- **Resource Cleanup**: Added proper disposal of SAPI synthesizer on destroy
- **Input Field Handling**: Improved null-safe handling of input field placeholders
- **Error Recovery**: NVDA availability is rechecked if initial speech fails

### Documentation
- Added **NVDA_SETUP.md**: Complete guide to setting up and configuring NVDA
- Added **TROUBLESHOOTING.md**: Comprehensive troubleshooting guide with common solutions
- Updated **README.md**: Added references to new documentation and enhanced features list
- Updated **QUICKSTART.md**: Added links to detailed setup guides
- Updated **lib/README.md**: Added NVDA Controller Client instructions

## [1.0.0] - Initial Release

### Added
- Initial release with basic screen reader support
- BepInEx-based plugin architecture
- Windows SAPI text-to-speech integration
- UI element tracking via Unity EventSystem
- Keyboard navigation support
- Button, Toggle, InputField, and Text component support
- Harmony patches for UI enhancement
- Automated installer script
- Basic configuration system
- Comprehensive documentation

### Features
- Works with NVDA, JAWS, Narrator
- Main menu accessibility
- Tab/Arrow key navigation
- Automatic UI element announcement
- Non-invasive installation

[Unreleased]: https://github.com/MadnessInnsmouth/MadnessInnsmouth/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases/tag/v1.0.0
