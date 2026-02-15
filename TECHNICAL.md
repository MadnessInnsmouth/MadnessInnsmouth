# Technical Documentation - FM26 Accessibility Plugin

This document provides technical details about how the FM26 Accessibility Plugin works.

## Architecture Overview

The plugin consists of three main components:

1. **BepInEx Plugin** - Loads into FM26 and provides the entry point
2. **Accessibility Manager** - Coordinates accessibility features
3. **Screen Reader Interface** - Communicates with Windows screen readers

### Component Diagram

```
FM26 Game (Unity)
    ↓
BepInEx Framework
    ↓
FM26AccessibilityPlugin
    ├─ AccessibilityManager
    │   ├─ ScreenReaderInterface
    │   └─ UIAccessibilityTracker
    └─ Harmony Patches (UIPatches)
```

## How It Works

### 1. Plugin Initialization

When FM26 starts with BepInEx installed:

```csharp
1. BepInEx loads all plugins from BepInEx/plugins/
2. FM26AccessibilityPlugin.Awake() is called
3. Harmony patches are applied to Unity UI components
4. AccessibilityManager GameObject is created
5. Screen reader detection begins
```

### 2. UI Tracking

The plugin monitors Unity's EventSystem to detect focused UI elements:

```csharp
void UpdateFocusedElement()
{
    var currentSelected = EventSystem.current.currentSelectedGameObject;
    if (currentSelected != null && currentSelected != lastFocusedObject)
    {
        lastFocusedObject = currentSelected;
        AnnounceUIElement(currentSelected);
    }
}
```

This runs continuously at 10Hz (configurable) to detect focus changes.

### 3. Element Announcement

When a UI element receives focus:

```csharp
1. Get the GameObject from EventSystem
2. Extract accessible name:
   - Check for Text component
   - Check for TextMeshPro component
   - Check for Button with child text
   - Check for Toggle with label
   - Check for InputField with placeholder
   - Fallback to GameObject.name
3. Format the announcement (add role: "Button:", "Checkbox:", etc.)
4. Send to ScreenReaderInterface.Speak()
```

### 4. Screen Reader Communication

The plugin uses multiple methods to communicate with screen readers:

#### Method 1: Windows SAPI (Speech API)
```csharp
System.Speech.Synthesis.SpeechSynthesizer
```
- Works with NVDA, JAWS, Narrator
- Direct text-to-speech output
- Most compatible method

#### Method 2: Native Screen Reader APIs
- NVDA: Uses NVDA Controller Client (planned)
- JAWS: Uses JAWS API (planned)
- Narrator: Uses UI Automation (planned)

### 5. Harmony Patches

The plugin uses Harmony to patch Unity methods at runtime:

#### Button.OnEnable Patch
```csharp
[HarmonyPatch(typeof(Button), "OnEnable")]
[HarmonyPostfix]
public static void Button_OnEnable_Postfix(Button __instance)
{
    // Ensure button is keyboard navigable
    var selectable = __instance.GetComponent<Selectable>();
    if (selectable != null)
    {
        selectable.navigation = new Navigation { mode = Navigation.Mode.Automatic };
    }
}
```

This ensures all buttons support keyboard navigation.

#### Canvas.Awake Patch
```csharp
[HarmonyPatch(typeof(Canvas), "Awake")]
[HarmonyPostfix]
public static void Canvas_Awake_Postfix(Canvas __instance)
{
    // Ensure EventSystem exists for input handling
    if (EventSystem.current == null)
    {
        var eventSystem = new GameObject("EventSystem");
        eventSystem.AddComponent<EventSystem>();
        eventSystem.AddComponent<StandaloneInputModule>();
    }
}
```

This guarantees input handling works even if FM26 doesn't create an EventSystem.

## Code Structure

### File Organization

```
src/FM26AccessibilityPlugin/
├── Plugin.cs               # Main plugin class and components
├── PluginInfo.cs          # Plugin metadata
└── FM26AccessibilityPlugin.csproj  # Project file
```

### Key Classes

#### AccessibilityPlugin (BepInEx Plugin)
- **Purpose**: Entry point for BepInEx
- **Lifecycle**: Created when FM26 starts
- **Responsibilities**:
  - Initialize Harmony
  - Create AccessibilityManager
  - Provide logging utilities

#### AccessibilityManager (MonoBehaviour)
- **Purpose**: Coordinates all accessibility features
- **Lifecycle**: Persistent across scenes (DontDestroyOnLoad)
- **Responsibilities**:
  - Manage child components
  - Update loop coordination
  - Component initialization

#### ScreenReaderInterface (MonoBehaviour)
- **Purpose**: Communicate with screen readers
- **Responsibilities**:
  - Detect running screen readers
  - Send text to be spoken
  - Manage speech queue
  - Handle interrupts

#### UIAccessibilityTracker (MonoBehaviour)
- **Purpose**: Track and announce UI elements
- **Responsibilities**:
  - Monitor EventSystem.currentSelectedGameObject
  - Extract accessible names from GameObjects
  - Format announcements with roles
  - Trigger speech output

#### UIPatches (Static Harmony Patches)
- **Purpose**: Runtime method interception
- **Responsibilities**:
  - Patch Unity UI methods
  - Ensure keyboard navigation
  - Ensure EventSystem exists

## Configuration

Plugin configuration is stored in:
```
<FM26_Directory>/BepInEx/config/com.accessibility.fm26.cfg
```

### Available Settings

```ini
[General]
EnableScreenReader = true
UpdateInterval = 0.1
EnableKeyboardNav = true

[Debug]
EnableDebugLogging = false
```

### Modifying Configuration

Users can edit the config file manually, or we can add an in-game configuration UI in future versions.

## Performance Considerations

### Update Frequency

The plugin checks for focused element changes 10 times per second (0.1s interval). This is configurable via `UpdateInterval`.

**Trade-offs:**
- Higher frequency = More responsive, but more CPU usage
- Lower frequency = Less CPU usage, but less responsive

### Memory Usage

The plugin maintains minimal state:
- Reference to last focused GameObject
- EventSystem reference
- String buffer for announcements (reused)

Estimated memory footprint: < 1 MB

### CPU Usage

Typical CPU impact:
- Idle (no focus changes): < 0.1%
- Active (frequent focus changes): < 1%
- Speech synthesis: Handled by Windows, not counted here

## Extending the Plugin

### Adding New UI Component Support

To support a new Unity UI component:

1. Add detection in `GetAccessibleName()`:
```csharp
var myComponent = obj.GetComponent<MyCustomComponent>();
if (myComponent != null)
{
    return $"My Role: {myComponent.GetText()}";
}
```

2. (Optional) Add a Harmony patch if initialization is needed:
```csharp
[HarmonyPatch(typeof(MyCustomComponent), "OnEnable")]
[HarmonyPostfix]
public static void MyCustomComponent_OnEnable_Postfix(MyCustomComponent __instance)
{
    // Setup accessibility
}
```

### Adding New Screen Reader Support

To add support for a different screen reader:

1. Add detection in `CheckScreenReaderActive()`:
```csharp
var processes = System.Diagnostics.Process.GetProcesses();
return processes.Any(p => p.ProcessName.ToLower().Contains("myreader"));
```

2. Add communication method in `SpeakWithSAPI()` or create new method:
```csharp
private void SpeakWithMyReader(string text, bool interrupt)
{
    // Use screen reader's specific API
}
```

### Adding Keyboard Shortcuts

To add custom keyboard shortcuts:

1. Add a MonoBehaviour component that handles input:
```csharp
public class AccessibilityKeyboardHandler : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.F1))
        {
            // Custom action
        }
    }
}
```

2. Attach in `AccessibilityManager.Initialize()`:
```csharp
var keyHandler = gameObject.AddComponent<AccessibilityKeyboardHandler>();
```

## Debugging

### Enable Debug Logging

Set in config file:
```ini
[Debug]
EnableDebugLogging = true
```

Or modify code:
```csharp
const bool DEBUG = true;
if (DEBUG) Logger.LogInfo($"Debug: {message}");
```

### Log Locations

- **BepInEx Console**: Appears when BepInEx loads (if enabled)
- **Log File**: `<FM26_Directory>/BepInEx/LogOutput.log`

### Common Debug Scenarios

#### UI Element Not Being Announced
1. Check if EventSystem exists
2. Verify element has a Selectable component
3. Check if element is in the navigation chain
4. Add debug logging in `GetAccessibleName()`

#### Screen Reader Not Speaking
1. Verify screen reader is detected (check logs for "Screen reader detected")
2. Test SAPI with Windows Narrator
3. Check Windows speech settings
4. Verify audio output device

#### Harmony Patch Not Applying
1. Check BepInEx logs for Harmony errors
2. Verify method signature matches
3. Try `[HarmonyPatch(typeof(Type), nameof(Type.Method))]` syntax
4. Use Harmony's debugging features

## Testing

### Manual Testing Checklist

- [ ] Plugin loads without errors
- [ ] Screen reader announces main menu items
- [ ] Tab key navigates between elements
- [ ] Enter key activates buttons
- [ ] Toggle states are announced
- [ ] Input fields announce their labels
- [ ] Screen transitions are handled
- [ ] Plugin survives scene changes

### Automated Testing

Currently, automated testing is limited due to the need for FM26 runtime. Future versions may include:
- Mock Unity components for unit testing
- Integration tests with Unity Test Framework
- Accessibility compliance tests

## Troubleshooting Guide for Developers

### Build Issues

**Issue**: Missing references
- **Solution**: Run `build/build.ps1` to download dependencies

**Issue**: Wrong .NET version
- **Solution**: Ensure .NET Framework 4.8 SDK is installed

### Runtime Issues

**Issue**: Plugin doesn't load
- **Solution**: Check BepInEx is installed correctly
- **Solution**: Verify DLL is in BepInEx/plugins/

**Issue**: Crashes on startup
- **Solution**: Check for missing dependencies
- **Solution**: Review stack trace in BepInEx logs

**Issue**: UI elements not accessible
- **Solution**: FM26 may use custom UI framework
- **Solution**: Investigate with Unity Explorer mod

## Future Improvements

### Planned Features

1. **Enhanced Screen Reader Support**
   - Direct NVDA integration
   - JAWS script support
   - Better Narrator integration

2. **UI Exploration Mode**
   - Navigate with arrow keys without changing selection
   - "Speak all" function for current screen
   - Describe UI hierarchy

3. **Customizable Announcements**
   - User-defined announcement formats
   - Language/localization support
   - Verbosity levels

4. **Game-Specific Features**
   - Match commentary accessibility
   - Tactics screen navigation
   - Data table reading

5. **Configuration UI**
   - In-game settings menu
   - Hotkey customization
   - Speech rate/voice selection

### Technical Debt

- Refactor monolithic Plugin.cs into separate files
- Add comprehensive error handling
- Implement proper event system instead of polling
- Add unit tests with mocked Unity components

## References

### Documentation
- BepInEx Docs: http://docs.bepinex.dev/
- Harmony Wiki: https://harmony.pardeike.net/
- Unity UI Docs: https://docs.unity3d.com/Packages/com.unity.ugui@1.0/manual/index.html

### Related Projects
- Unity Accessibility Plugin: https://github.com/mikrima/UnityAccessibilityPlugin
- NVDA: https://www.nvaccess.org/
- Unity Explorer: https://github.com/sinai-dev/UnityExplorer

## License

This project is licensed under the MIT License. See LICENSE file for details.
