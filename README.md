# FM26 Accessibility Mod

A comprehensive accessibility modification for Football Manager 2026 that makes the game fully accessible to screen readers and blind players.

> **⚡ Quick Start:** See [QUICKSTART.md](QUICKSTART.md) for step-by-step installation instructions!

## ✨ Features

- 🔊 **Full Screen Reader Support** - Works with NVDA, JAWS, Narrator, and other Windows screen readers
- 🎯 **Direct NVDA Integration** - Enhanced NVDA support via Controller Client for faster, more reliable announcements
- 🎮 **Main Menu Accessibility** - Navigate all menus entirely with keyboard and screen reader
- ⌨️ **Keyboard Navigation** - Tab through UI elements, use arrow keys for lists
- 🎯 **Automatic Element Detection** - Buttons, toggles, input fields, and text are automatically announced
- ⚡ **Easy Installation** - One-click installer that sets up everything automatically
- 🔄 **Auto-Download Dependencies** - Installer downloads BepInEx and all requirements
- 🛡️ **Non-Invasive** - Uses BepInEx plugin framework, doesn't modify game files directly
- 🔧 **Configurable** - Adjust update frequency and other settings
- 🔄 **Robust Error Handling** - Graceful fallbacks ensure mod keeps working
- 📝 **Open Source** - MIT licensed, community contributions welcome

## 📋 Requirements

- ✅ **Football Manager 2026** (Steam, Xbox Game Pass, or Epic Games version)
- ✅ **Windows 10/11** (64-bit)
- ✅ **.NET Framework 4.8** or higher (usually already installed)
- ✅ **Screen Reader** - Choose one:
  - [NVDA](https://www.nvaccess.org/download/) (Free, recommended)
  - [JAWS](https://www.freedomscientific.com/products/software/jaws/)
  - Windows Narrator (built-in, press Windows+Ctrl+Enter)

## 🚀 Installation

### Option 1: Quick Install (Recommended)

1. **Download** the latest release from the [Releases page](https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases)
2. **Extract** the ZIP file
3. **Run** `Install-FM26Accessibility.bat` (double-click to launch the installer)
4. **Follow** the on-screen instructions
5. **Launch** Football Manager 2026

That's it! The installer handles everything else automatically.

### Option 2: Manual Installation

See [BUILD.md](BUILD.md) for manual installation and building from source.

## 📖 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Step-by-step installation and first-time usage
- **[NVDA_SETUP.md](NVDA_SETUP.md)** - Complete NVDA setup and configuration guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Comprehensive troubleshooting guide
- **[BUILD.md](BUILD.md)** - Building from source and development setup
- **[TECHNICAL.md](TECHNICAL.md)** - Technical architecture and API documentation
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute to the project

## 🎮 Usage

Once installed:

1. **Start your screen reader** (if not already running)
2. **Launch Football Manager 2026**
3. **Navigate** with these keys:
   - **Tab** / **Shift+Tab** - Move between UI elements
   - **Arrow Keys** - Navigate within lists and menus
   - **Enter** - Select/Activate
   - **Space** - Toggle checkboxes
   - **Escape** - Go back/Cancel

### First Launch

The first time you launch FM26 after installing the mod:
1. Wait a few seconds for BepInEx to initialize
2. The mod will start automatically
3. Navigate the main menu with Tab key
4. Your screen reader will announce each UI element

## 🔧 Configuration

The mod can be configured by editing:
```
<FM26_Directory>/BepInEx/config/com.accessibility.fm26.cfg
```

Available settings:
- Enable/disable screen reader support
- Adjust UI update frequency
- Enable keyboard navigation
- Debug logging

## 🐛 Troubleshooting

### Screen Reader Not Working

1. Ensure your screen reader is running **before** launching FM26
2. Check BepInEx log: `<FM26_Directory>/BepInEx/LogOutput.log`
3. Look for: "FM26 Accessibility Plugin initialized successfully!"

### Mod Not Loading

1. Verify BepInEx is installed (check for `BepInEx` folder in FM26 directory)
2. Confirm plugin exists: `BepInEx/plugins/FM26AccessibilityPlugin.dll`
3. Launch FM26 once to generate config files, then try again

### Installation Issues

- Run installer as Administrator
- Manually specify FM26 path if auto-detection fails
- Re-run installer with `-Force` flag to reinstall

For more help, see the comprehensive **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** guide, [NVDA_SETUP.md](NVDA_SETUP.md) for NVDA-specific issues, or [open an issue](https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues).

## 🤝 Contributing

Contributions are welcome! Whether you:
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 💻 Write code
- 🧪 Test the mod

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🏗️ How It Works

This mod uses:

- **[BepInEx](https://github.com/BepInEx/BepInEx)** - Unity game modding framework for code injection
- **[HarmonyX](https://github.com/BepInEx/HarmonyX)** - Runtime method patching to intercept UI creation
- **Windows SAPI** - Native speech synthesis for screen reader output
- **Unity EventSystem** - Tracks UI focus and navigation

The mod intercepts Football Manager's UI creation and adds accessibility metadata to all UI elements, making them readable by screen readers.

See [TECHNICAL.md](TECHNICAL.md) for detailed architecture information.

## 📊 Project Status

- ✅ Core functionality implemented
- ✅ Main menu accessibility working
- ✅ Installer automated
- ✅ Documentation complete
- 🔄 Testing in progress (requires FM26)
- 🔄 Community feedback gathering
- 🔄 Advanced features in development

## 🗺️ Roadmap

### Version 1.0 (Current)
- [x] Basic screen reader support
- [x] Main menu accessibility
- [x] Keyboard navigation
- [x] Automated installer
- [ ] User testing and feedback

### Version 1.1 (Planned)
- [ ] Enhanced NVDA integration
- [ ] JAWS script support
- [ ] Match screen accessibility
- [ ] Tactics screen navigation
- [ ] Multi-language support

### Version 2.0 (Future)
- [ ] Real-time match commentary
- [ ] Data table reading
- [ ] Custom hotkeys
- [ ] In-game settings UI
- [ ] Mobile accessibility (if applicable)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

- BepInEx: LGPL-2.1
- HarmonyX: MIT
- Football Manager: © Sports Interactive / SEGA (game not included)

## 🙏 Credits

- **BepInEx Team** - For the excellent modding framework
- **Harmony Team** - For runtime patching capabilities
- **Unity Accessibility Plugin** - For inspiration and best practices
- **NVDA Community** - For testing and feedback
- **Contributors** - See GitHub contributors page

## ⚠️ Disclaimer

This is an unofficial mod and is not affiliated with, endorsed by, or connected to Sports Interactive or SEGA. Football Manager is a trademark of Sports Interactive.

Use at your own risk. Always backup your save files before using mods.

## 💬 Support & Community

- **Questions**: [GitHub Discussions](https://github.com/MadnessInnsmouth/MadnessInnsmouth/discussions)
- **Bug Reports**: [GitHub Issues](https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues)
- **Documentation**: [Wiki](https://github.com/MadnessInnsmouth/MadnessInnsmouth/wiki)

## ⭐ Show Your Support

If this mod helps you enjoy Football Manager 2026:
- ⭐ Star this repository
- 🐛 Report bugs you find
- 💡 Suggest improvements
- 📢 Share with others who might benefit
- 🤝 Contribute code or documentation

---

<div align="center">

**Made with ❤️ for the accessible gaming community**

[Download](https://github.com/MadnessInnsmouth/MadnessInnsmouth/releases) • [Documentation](QUICKSTART.md) • [Contribute](CONTRIBUTING.md) • [Support](https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues)

</div>
