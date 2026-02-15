# FM26 Accessibility Mod

A comprehensive accessibility modification for Football Manager 2026 that makes the game fully accessible to screen readers and blind players.

## Features

- 🔊 **Screen Reader Support** - All UI elements are read by screen readers (NVDA, JAWS, Narrator, VoiceOver)
- 🎮 **Main Menu Accessibility** - Navigate the main menu entirely with a screen reader
- ⚡ **Easy Installation** - Automated installer that detects FM26 and sets up everything
- 🔄 **Auto-Download Dependencies** - Installer automatically downloads BepInEx and required components
- 🛡️ **Non-Invasive** - Uses BepInEx plugin framework, doesn't modify game files directly

## Requirements

- Football Manager 2026 (Steam or Xbox Game Pass version)
- Windows 10/11 (64-bit)
- .NET Framework 4.8 or higher
- Screen reader software (NVDA recommended - free and open source)

## Installation

### Quick Install (Recommended)

1. Download the latest release from the [Releases page](https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases)
2. Run `Install-FM26Accessibility.ps1` as Administrator (right-click > Run with PowerShell)
3. Follow the on-screen prompts
4. Launch Football Manager 2026
5. The accessibility mod will automatically activate

### Manual Installation

1. Install [BepInEx 5.x](https://github.com/BepInEx/BepInEx/releases) to your FM26 directory
2. Copy `FM26AccessibilityPlugin.dll` to `<FM26_Directory>/BepInEx/plugins/`
3. Copy the `UAP` folder to `<FM26_Directory>/BepInEx/plugins/`
4. Launch the game

## Usage

Once installed:

1. Launch Football Manager 2026
2. Your screen reader will automatically start reading UI elements
3. Use **Tab** to navigate between menu items
4. Use **Enter** to select items
5. Use **Arrow keys** for additional navigation

### Keyboard Shortcuts

- **Tab** - Move to next UI element
- **Shift+Tab** - Move to previous UI element
- **Enter** - Activate selected element
- **Arrow Keys** - Navigate within lists and menus
- **Escape** - Go back/close dialogs

## Troubleshooting

### Screen reader not working

1. Ensure your screen reader (NVDA/JAWS/Narrator) is running BEFORE launching FM26
2. Check that BepInEx is installed correctly (a `BepInEx` folder should exist in your FM26 directory)
3. Check the BepInEx log at `<FM26_Directory>/BepInEx/LogOutput.log`

### Mod not loading

1. Verify FM26 is installed (installer should detect it automatically)
2. Run the game once to generate BepInEx configuration files
3. Check that `FM26AccessibilityPlugin.dll` exists in `BepInEx/plugins/`

### Game crashes

1. Remove other BepInEx plugins temporarily to check for conflicts
2. Ensure you're using BepInEx 5.4.x or higher
3. Report the issue with logs from `BepInEx/LogOutput.log`

## How It Works

This mod uses:

- **BepInEx** - A plugin framework for Unity games that allows runtime code injection
- **Unity Accessibility Plugin (UAP)** - Open-source accessibility framework for Unity UI
- **Harmony** - Runtime method patching for intercepting game UI creation

The mod intercepts Football Manager's UI creation and adds accessibility components to all UI elements, making them readable by screen readers.

## Building from Source

### Prerequisites

- Visual Studio 2019 or later (or Rider)
- .NET Framework 4.8 SDK
- BepInEx 5.x developer pack

### Build Steps

```bash
# Clone the repository
git clone https://github.com/MadnessInnsmouth/MadnessInnsmouth.git
cd MadnessInnsmouth

# Restore NuGet packages
dotnet restore src/FM26AccessibilityPlugin/FM26AccessibilityPlugin.csproj

# Build the plugin
dotnet build src/FM26AccessibilityPlugin/FM26AccessibilityPlugin.csproj --configuration Release

# Output will be in src/FM26AccessibilityPlugin/bin/Release/
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- **BepInEx** - https://github.com/BepInEx/BepInEx
- **Unity Accessibility Plugin** - https://github.com/mikrima/UnityAccessibilityPlugin
- **HarmonyX** - https://github.com/BepInEx/HarmonyX

## Disclaimer

This is an unofficial mod and is not affiliated with, endorsed by, or connected to Sports Interactive or SEGA. Football Manager is a trademark of Sports Interactive.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check the [Wiki](https://github.com/MadnessInnsmouth/MadnessInnsmouth/wiki) for detailed guides

---

Made with ❤️ for the accessible gaming community
