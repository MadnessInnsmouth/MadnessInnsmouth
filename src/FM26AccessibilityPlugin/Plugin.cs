using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;

namespace FM26AccessibilityPlugin
{
    [BepInPlugin(PluginInfo.PLUGIN_GUID, PluginInfo.PLUGIN_NAME, PluginInfo.PLUGIN_VERSION)]
    public class AccessibilityPlugin : BaseUnityPlugin
    {
        private static ManualLogSource logSource;
        private Harmony harmony;

        private void Awake()
        {
            logSource = Logger;
            Logger.LogInfo($"Plugin {PluginInfo.PLUGIN_GUID} is loaded!");
            Logger.LogInfo("Initializing FM26 Accessibility Plugin...");

            try
            {
                // Initialize Harmony for patching
                harmony = new Harmony(PluginInfo.PLUGIN_GUID);
                harmony.PatchAll();
                Logger.LogInfo("Harmony patches applied successfully!");

                // Initialize the accessibility manager
                StartCoroutine(InitializeAccessibilityManager());
                
                Logger.LogInfo("FM26 Accessibility Plugin initialized successfully!");
            }
            catch (Exception ex)
            {
                Logger.LogError($"Failed to initialize plugin: {ex}");
            }
        }

        private System.Collections.IEnumerator InitializeAccessibilityManager()
        {
            // Wait a few frames to ensure Unity is ready
            for (int i = 0; i < 10; i++)
            {
                yield return null;
            }

            try
            {
                // Create the accessibility manager GameObject
                var managerObj = new GameObject("FM26AccessibilityManager");
                DontDestroyOnLoad(managerObj);
                
                var manager = managerObj.AddComponent<AccessibilityManager>();
                manager.Initialize(Logger);
                
                Logger.LogInfo("Accessibility Manager created successfully!");
            }
            catch (Exception ex)
            {
                Logger.LogError($"Failed to create Accessibility Manager: {ex}");
            }
        }

        private void OnDestroy()
        {
            harmony?.UnpatchSelf();
        }

        internal static void Log(string message)
        {
            logSource?.LogInfo(message);
        }

        internal static void LogWarning(string message)
        {
            logSource?.LogWarning(message);
        }

        internal static void LogError(string message)
        {
            logSource?.LogError(message);
        }
    }

    /// <summary>
    /// Main accessibility manager that handles screen reader integration
    /// </summary>
    public class AccessibilityManager : MonoBehaviour
    {
        private ManualLogSource logger;
        private ScreenReaderInterface screenReader;
        private UIAccessibilityTracker uiTracker;
        private MainMenuNarrator menuNarrator;
        private float updateInterval = 0.1f;
        private float nextUpdate = 0f;
        private string lastSceneName = "";

        public void Initialize(ManualLogSource log)
        {
            logger = log;
            logger.LogInfo("Initializing Accessibility Manager...");

            try
            {
                // Initialize screen reader interface
                screenReader = gameObject.AddComponent<ScreenReaderInterface>();
                screenReader.Initialize(logger);

                // Initialize UI tracker
                uiTracker = gameObject.AddComponent<UIAccessibilityTracker>();
                uiTracker.Initialize(logger, screenReader);

                // Initialize main menu narrator
                menuNarrator = gameObject.AddComponent<MainMenuNarrator>();
                menuNarrator.Initialize(logger, screenReader);

                // Listen for scene changes
                SceneManager.sceneLoaded += OnSceneLoaded;

                logger.LogInfo("Accessibility Manager components initialized!");
            }
            catch (Exception ex)
            {
                logger.LogError($"Error initializing Accessibility Manager: {ex}");
            }
        }

        private void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            try
            {
                if (scene.name != lastSceneName)
                {
                    lastSceneName = scene.name;
                    logger?.LogInfo($"Scene changed to: {scene.name}");
                    screenReader?.Speak($"Screen: {scene.name}", true);
                    // Notify menu narrator to re-scan
                    menuNarrator?.ResetScan();
                }
            }
            catch (Exception ex)
            {
                logger?.LogError($"Error handling scene change: {ex}");
            }
        }

        private void Update()
        {
            if (Time.time >= nextUpdate)
            {
                nextUpdate = Time.time + updateInterval;
                
                try
                {
                    // Check for focused UI element changes
                    uiTracker?.UpdateFocusedElement();
                }
                catch (Exception ex)
                {
                    logger?.LogError($"Error in Update: {ex}");
                }
            }
        }

        private void OnDestroy()
        {
            SceneManager.sceneLoaded -= OnSceneLoaded;
        }
    }

    /// <summary>
    /// Detects main menu screens and narrates menu items for screen reader users.
    /// Scans for common FM main-menu labels such as Continue, New Game, Load Game, etc.
    /// and announces them when a new menu screen is loaded.  Also scans all Selectable
    /// components as a fallback to ensure FM26 menus are captured even when buttons
    /// use non-standard labelling.
    /// </summary>
    public class MainMenuNarrator : MonoBehaviour
    {
        private ManualLogSource logger;
        private ScreenReaderInterface screenReader;

        // Known main-menu button labels (case-insensitive matching)
        private static readonly string[] MainMenuLabels = new[]
        {
            "continue", "new game", "load game", "start game",
            "preferences", "options", "settings",
            "create a club", "fantasy draft",
            "online", "multiplayer",
            "editor", "extras", "credits",
            "exit", "quit",
            // FM26-specific labels
            "career", "versus", "training",
            "challenges", "play", "manage",
            "fm touch", "fm classic",
            "steam workshop", "community",
            "tutorials", "help", "about",
            "back", "cancel", "ok", "confirm",
            "save", "save game", "save & exit"
        };

        private int lastButtonHash = 0;
        private float scanInterval = 1.0f;
        private float nextScan = 0f;
        private bool hasAnnounced = false;

        public void Initialize(ManualLogSource log, ScreenReaderInterface reader)
        {
            logger = log;
            screenReader = reader;
            logger.LogInfo("MainMenuNarrator initialized. Will scan for main menu screens.");
        }

        /// <summary>
        /// Resets the scan so the next Update cycle will re-announce the current menu.
        /// Called when a scene change is detected or UI significantly changes.
        /// </summary>
        public void ResetScan()
        {
            lastButtonHash = 0;
            hasAnnounced = false;
        }

        private void Update()
        {
            if (Time.time < nextScan)
                return;
            nextScan = Time.time + scanInterval;

            try
            {
                ScanForMainMenu();
            }
            catch (Exception ex)
            {
                logger?.LogError($"MainMenuNarrator scan error: {ex}");
            }
        }

        private void ScanForMainMenu()
        {
            // Gather all active Selectables (buttons, toggles, dropdowns, sliders, etc.)
            var allSelectables = FindObjectsOfType<Selectable>();
            if (allSelectables == null || allSelectables.Length == 0)
                return;

            // Collect menu item labels that match known main-menu entries
            var menuItems = new List<string>();
            var menuSelectables = new List<Selectable>();

            foreach (var sel in allSelectables)
            {
                if (sel == null || !sel.gameObject.activeInHierarchy || !sel.interactable)
                    continue;

                string label = GetSelectableLabel(sel);
                if (string.IsNullOrEmpty(label))
                    continue;

                string lower = label.ToLowerInvariant();
                foreach (string known in MainMenuLabels)
                {
                    if (lower.Contains(known))
                    {
                        menuItems.Add(label);
                        menuSelectables.Add(sel);
                        break;
                    }
                }
            }

            // Fall back to announcing ALL selectables if none matched known labels
            // but there are interactive elements on screen (ensures FM26 menus are read)
            if (menuItems.Count == 0 && allSelectables.Length > 0)
            {
                foreach (var sel in allSelectables)
                {
                    if (sel == null || !sel.gameObject.activeInHierarchy || !sel.interactable)
                        continue;

                    string label = GetSelectableLabel(sel);
                    if (!string.IsNullOrEmpty(label))
                    {
                        menuItems.Add(label);
                        menuSelectables.Add(sel);
                    }
                }
            }

            if (menuItems.Count == 0)
                return;

            // Compute hash from matched items to avoid false re-announcements
            int hash = menuItems.Count;
            foreach (string item in menuItems)
                hash = hash * 31 + item.GetHashCode();

            if (hash != lastButtonHash)
            {
                lastButtonHash = hash;
                hasAnnounced = false;
                logger?.LogInfo("MainMenuNarrator: detected menu changes, re-scanning...");
            }

            if (hasAnnounced)
                return;

            // Build announcement
            string announcement = $"Menu. {menuItems.Count} items: " + string.Join(", ", menuItems.ToArray());
            logger?.LogInfo($"MainMenuNarrator announcing: {announcement}");
            screenReader?.Speak(announcement, true);
            hasAnnounced = true;

            // Focus the first selectable menu item so keyboard navigation works immediately
            if (menuSelectables.Count > 0)
            {
                var es = EventSystem.current;
                if (es != null)
                {
                    es.SetSelectedGameObject(menuSelectables[0].gameObject);
                    logger?.LogInfo($"MainMenuNarrator: focused first menu item '{menuItems[0]}'");
                }
            }
        }

        private string GetSelectableLabel(Selectable sel)
        {
            if (sel == null)
                return null;

            // Try child Text component
            var text = sel.GetComponentInChildren<Text>();
            if (text != null && !string.IsNullOrEmpty(text.text))
                return text.text.Trim();

            // Try TextMeshPro (FM26 likely uses TMP for all UI text)
            try
            {
                var tmp = sel.GetComponentInChildren<TMPro.TextMeshProUGUI>();
                if (tmp != null && !string.IsNullOrEmpty(tmp.text))
                    return tmp.text.Trim();
            }
            catch { }

            // Fall back to the GameObject name
            string objName = sel.gameObject.name;
            if (!string.IsNullOrEmpty(objName))
                return objName;

            return null;
        }
    }

    /// <summary>
    /// NVDA Controller Client API wrapper for direct NVDA communication
    /// </summary>
    public static class NVDAController
    {
        private const string NVDA_DLL = "nvdaControllerClient64.dll";
        
        [DllImport(NVDA_DLL, CallingConvention = CallingConvention.Cdecl)]
        private static extern int nvdaController_testIfRunning();
        
        [DllImport(NVDA_DLL, CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Unicode)]
        private static extern int nvdaController_speakText([MarshalAs(UnmanagedType.LPWStr)] string text);
        
        [DllImport(NVDA_DLL, CallingConvention = CallingConvention.Cdecl)]
        private static extern int nvdaController_cancelSpeech();
        
        public static bool IsRunning()
        {
            try
            {
                return nvdaController_testIfRunning() == 0;
            }
            catch
            {
                return false;
            }
        }
        
        public static bool Speak(string text)
        {
            try
            {
                return nvdaController_speakText(text) == 0;
            }
            catch
            {
                return false;
            }
        }
        
        public static bool CancelSpeech()
        {
            try
            {
                return nvdaController_cancelSpeech() == 0;
            }
            catch
            {
                return false;
            }
        }
    }

    /// <summary>
    /// Handles communication with Windows screen readers (NVDA, JAWS, Narrator).
    /// Periodically re-checks NVDA availability so the plugin adapts when a screen reader
    /// is started after the game is already running.
    /// </summary>
    public class ScreenReaderInterface : MonoBehaviour
    {
        private ManualLogSource logger;
        private bool isScreenReaderActive = false;
        private bool isNVDAAvailable = false;
        private bool isSAPIAvailable = false;
        private object sapiSynthesizer = null;
        private float nextScreenReaderCheck = 0f;
        private const float ScreenReaderCheckInterval = 10f;

        public void Initialize(ManualLogSource log)
        {
            logger = log;
            logger.LogInfo("Initializing Screen Reader Interface...");

            try
            {
                // Check for NVDA first
                isNVDAAvailable = CheckNVDAAvailability();
                
                // Check if any screen reader is running
                isScreenReaderActive = CheckScreenReaderActive();
                
                // Initialize SAPI as fallback
                if (!isNVDAAvailable)
                {
                    isSAPIAvailable = InitializeSAPI();
                }
                
                LogScreenReaderStatus();
            }
            catch (Exception ex)
            {
                logger.LogError($"Error initializing Screen Reader Interface: {ex}");
            }
        }

        private void Update()
        {
            // Periodically re-check screen reader availability
            if (Time.time >= nextScreenReaderCheck)
            {
                nextScreenReaderCheck = Time.time + ScreenReaderCheckInterval;
                try
                {
                    bool wasAvailable = isNVDAAvailable;
                    isNVDAAvailable = CheckNVDAAvailability();
                    if (!wasAvailable && isNVDAAvailable)
                    {
                        logger?.LogInfo("NVDA is now available! Speech output will use NVDA on next call.");
                    }
                    if (!isNVDAAvailable && !isSAPIAvailable)
                    {
                        isSAPIAvailable = InitializeSAPI();
                    }
                    isScreenReaderActive = isNVDAAvailable || CheckScreenReaderActive();
                }
                catch (Exception ex)
                {
                    logger?.LogWarning($"Error during screen reader re-check: {ex.Message}");
                }
            }
        }

        private bool CheckNVDAAvailability()
        {
            try
            {
                bool nvdaRunning = NVDAController.IsRunning();
                if (nvdaRunning)
                {
                    logger.LogInfo("NVDA Controller Client is available and NVDA is running!");
                    return true;
                }
                else
                {
                    logger.LogInfo("NVDA is not currently running or Controller Client not available.");
                    return false;
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning($"Could not connect to NVDA: {ex.Message}");
                return false;
            }
        }

        private bool CheckScreenReaderActive()
        {
            try
            {
                // On Windows, check for common screen readers
                var processes = System.Diagnostics.Process.GetProcesses();
                var screenReaderProcesses = new[] { "nvda", "jaws", "narrator", "windoweyes", "zoomtext" };
                
                return processes.Any(p => 
                    screenReaderProcesses.Any(sr => 
                        p.ProcessName.ToLower().Contains(sr)
                    )
                );
            }
            catch (Exception ex)
            {
                logger?.LogWarning($"Could not check for screen reader processes: {ex.Message}");
                return false;
            }
        }

        private bool InitializeSAPI()
        {
            try
            {
                var type = Type.GetType("System.Speech.Synthesis.SpeechSynthesizer, System.Speech, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35");
                
                if (type != null)
                {
                    sapiSynthesizer = Activator.CreateInstance(type);
                    logger.LogInfo("Windows SAPI initialized successfully.");
                    return true;
                }
                else
                {
                    logger.LogWarning("System.Speech assembly not available. Text-to-speech may not work.");
                    return false;
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning($"Could not initialize SAPI: {ex.Message}");
                return false;
            }
        }

        private void LogScreenReaderStatus()
        {
            if (isNVDAAvailable)
            {
                logger.LogInfo("✓ NVDA is active and will receive direct announcements");
            }
            else if (isScreenReaderActive && isSAPIAvailable)
            {
                logger.LogInfo("✓ Screen reader detected. Using Windows SAPI for announcements");
            }
            else if (isSAPIAvailable)
            {
                logger.LogWarning("No screen reader detected, but SAPI is available. You may hear system TTS.");
            }
            else
            {
                logger.LogError("⚠ No screen reader detected and SAPI unavailable. Accessibility features limited.");
            }
        }

        public void Speak(string text, bool interrupt = false)
        {
            if (string.IsNullOrEmpty(text))
                return;

            try
            {
                // Log what would be spoken
                logger?.LogInfo($"[Screen Reader] {text}");

                bool spoken = false;

                // Try NVDA first if available
                if (isNVDAAvailable)
                {
                    if (interrupt)
                    {
                        NVDAController.CancelSpeech();
                    }
                    spoken = NVDAController.Speak(text);
                    
                    if (spoken)
                    {
                        logger?.LogInfo("Spoke via NVDA Controller Client");
                        return;
                    }
                    else
                    {
                        // NVDA may have closed, try to reinitialize
                        logger?.LogWarning("NVDA speech failed, checking availability...");
                        isNVDAAvailable = CheckNVDAAvailability();
                    }
                }

                // Fallback to SAPI if NVDA unavailable or failed
                if (isSAPIAvailable && sapiSynthesizer != null)
                {
                    SpeakWithSAPI(text, interrupt);
                    logger?.LogInfo("Spoke via Windows SAPI");
                }
                else
                {
                    logger?.LogWarning($"Could not speak text (no screen reader available): {text}");
                }
            }
            catch (Exception ex)
            {
                logger?.LogError($"Error speaking text: {ex}");
            }
        }

        private void SpeakWithSAPI(string text, bool interrupt)
        {
            try
            {
                if (sapiSynthesizer == null)
                    return;

                dynamic synth = sapiSynthesizer;
                
                if (interrupt)
                {
                    synth.SpeakAsyncCancelAll();
                }
                
                synth.SpeakAsync(text);
            }
            catch (Exception ex)
            {
                logger?.LogWarning($"SAPI TTS error: {ex.Message}");
                isSAPIAvailable = false;
            }
        }

        private void OnDestroy()
        {
            // Clean up SAPI synthesizer
            if (sapiSynthesizer != null)
            {
                try
                {
                    dynamic synth = sapiSynthesizer;
                    synth.Dispose();
                }
                catch { }
                sapiSynthesizer = null;
            }
        }
    }

    /// <summary>
    /// Tracks UI elements and makes them accessible.
    /// Supports Buttons, Toggles, InputFields, Dropdowns, Sliders, and ScrollRects.
    /// </summary>
    public class UIAccessibilityTracker : MonoBehaviour
    {
        private ManualLogSource logger;
        private ScreenReaderInterface screenReader;
        private GameObject lastFocusedObject;
        private EventSystem eventSystem;

        public void Initialize(ManualLogSource log, ScreenReaderInterface reader)
        {
            logger = log;
            screenReader = reader;
            
            logger.LogInfo("Initializing UI Accessibility Tracker...");
            
            // Find or create EventSystem
            eventSystem = EventSystem.current;
            if (eventSystem == null)
            {
                logger.LogWarning("No EventSystem found. UI navigation may not work properly.");
            }
        }

        public void UpdateFocusedElement()
        {
            try
            {
                if (eventSystem == null)
                {
                    eventSystem = EventSystem.current;
                    if (eventSystem == null)
                    {
                        // No EventSystem available yet, skip this update
                        return;
                    }
                }

                var currentSelected = eventSystem.currentSelectedGameObject;
                
                if (currentSelected != null && currentSelected != lastFocusedObject)
                {
                    lastFocusedObject = currentSelected;
                    AnnounceUIElement(currentSelected);
                }
            }
            catch (Exception ex)
            {
                logger?.LogError($"Error updating focused element: {ex}");
            }
        }

        private void AnnounceUIElement(GameObject obj)
        {
            if (obj == null) return;

            try
            {
                string announcement = GetAccessibleName(obj);
                
                if (!string.IsNullOrEmpty(announcement))
                {
                    screenReader?.Speak(announcement, true);
                }
            }
            catch (Exception ex)
            {
                logger?.LogError($"Error announcing UI element: {ex}");
            }
        }

        private string GetAccessibleName(GameObject obj)
        {
            if (obj == null) return "";

            try
            {
                // Check for button first (most common in menus)
                var button = obj.GetComponent<Button>();
                if (button != null)
                {
                    string btnLabel = GetChildText(obj);
                    return $"Button: {(!string.IsNullOrEmpty(btnLabel) ? btnLabel : obj.name)}";
                }

                // Check for toggle / checkbox
                var toggle = obj.GetComponent<Toggle>();
                if (toggle != null)
                {
                    string state = toggle.isOn ? "checked" : "unchecked";
                    string toggleLabel = GetChildText(obj);
                    return $"Checkbox {state}: {(!string.IsNullOrEmpty(toggleLabel) ? toggleLabel : obj.name)}";
                }

                // Check for dropdown
                var dropdown = obj.GetComponent<Dropdown>();
                if (dropdown != null)
                {
                    string dropLabel = GetChildText(obj);
                    string selectedOption = (dropdown.options != null && dropdown.value >= 0 && dropdown.value < dropdown.options.Count)
                        ? dropdown.options[dropdown.value].text
                        : "";
                    string label = !string.IsNullOrEmpty(dropLabel) ? dropLabel : obj.name;
                    if (!string.IsNullOrEmpty(selectedOption))
                        return $"Dropdown: {label}. Selected: {selectedOption}";
                    return $"Dropdown: {label}";
                }

                // Check for slider
                var slider = obj.GetComponent<Slider>();
                if (slider != null)
                {
                    string sliderLabel = GetChildText(obj);
                    string label = !string.IsNullOrEmpty(sliderLabel) ? sliderLabel : obj.name;
                    int percent = 0;
                    float range = slider.maxValue - slider.minValue;
                    if (range > 0f)
                        percent = Mathf.RoundToInt(((slider.value - slider.minValue) / range) * 100f);
                    return $"Slider: {label}. Value: {percent} percent";
                }

                // Check for input field
                var inputField = obj.GetComponent<InputField>();
                if (inputField != null)
                {
                    string placeholderText = "";
                    if (inputField.placeholder != null)
                    {
                        var placeholderTextComp = inputField.placeholder.GetComponent<Text>();
                        if (placeholderTextComp != null)
                        {
                            placeholderText = placeholderTextComp.text;
                        }
                    }
                    
                    string label = !string.IsNullOrEmpty(placeholderText) ? placeholderText : obj.name;
                    return $"Input field: {label}. Current value: {inputField.text}";
                }

                // Check for scrollrect (scroll view containers)
                var scrollRect = obj.GetComponent<ScrollRect>();
                if (scrollRect != null)
                {
                    return $"Scroll view: {obj.name}";
                }

                // Generic selectable
                var selectable = obj.GetComponent<Selectable>();
                if (selectable != null)
                {
                    string selLabel = GetChildText(obj);
                    return !string.IsNullOrEmpty(selLabel) ? selLabel : obj.name;
                }

                // Try direct text on the object itself
                string directText = GetDirectText(obj);
                if (!string.IsNullOrEmpty(directText))
                    return directText;

                // Fallback to object name
                return obj.name;
            }
            catch (Exception ex)
            {
                logger?.LogError($"Error getting accessible name: {ex}");
                return obj?.name ?? "Unknown";
            }
        }

        /// <summary>
        /// Gets text from the object's children (Text or TextMeshProUGUI).
        /// </summary>
        private string GetChildText(GameObject obj)
        {
            if (obj == null) return null;

            var text = obj.GetComponentInChildren<Text>();
            if (text != null && !string.IsNullOrEmpty(text.text))
                return text.text.Trim();

            try
            {
                var tmp = obj.GetComponentInChildren<TMPro.TextMeshProUGUI>();
                if (tmp != null && !string.IsNullOrEmpty(tmp.text))
                    return tmp.text.Trim();
            }
            catch { }

            return null;
        }

        /// <summary>
        /// Gets text directly on the object (not children).
        /// </summary>
        private string GetDirectText(GameObject obj)
        {
            if (obj == null) return null;

            var text = obj.GetComponent<Text>();
            if (text != null && !string.IsNullOrEmpty(text.text))
                return text.text.Trim();

            try
            {
                var tmp = obj.GetComponent<TMPro.TextMeshProUGUI>();
                if (tmp != null && !string.IsNullOrEmpty(tmp.text))
                    return tmp.text.Trim();
            }
            catch { }

            return null;
        }
    }

    /// <summary>
    /// Harmony patches for intercepting Unity UI creation.
    /// Ensures all Selectables are keyboard-navigable and that an EventSystem always exists.
    /// </summary>
    [HarmonyPatch]
    public static class UIPatches
    {
        // Patch Selectable.OnEnable to ensure all interactive elements are keyboard-navigable
        [HarmonyPatch(typeof(Selectable), "OnEnable")]
        [HarmonyPostfix]
        public static void Selectable_OnEnable_Postfix(Selectable __instance)
        {
            try
            {
                if (__instance != null && __instance.navigation.mode == Navigation.Mode.None)
                {
                    __instance.navigation = new Navigation { mode = Navigation.Mode.Automatic };
                }
            }
            catch (Exception ex)
            {
                AccessibilityPlugin.LogError($"Error in Selectable_OnEnable patch: {ex}");
            }
        }

        // Patch Canvas to ensure EventSystem exists
        [HarmonyPatch(typeof(Canvas), "Awake")]
        [HarmonyPostfix]
        public static void Canvas_Awake_Postfix(Canvas __instance)
        {
            try
            {
                if (EventSystem.current == null)
                {
                    var eventSystem = new GameObject("EventSystem");
                    eventSystem.AddComponent<EventSystem>();
                    eventSystem.AddComponent<StandaloneInputModule>();
                    AccessibilityPlugin.Log("Created EventSystem for UI navigation");
                }
            }
            catch (Exception ex)
            {
                AccessibilityPlugin.LogError($"Error in Canvas_Awake patch: {ex}");
            }
        }
    }
}
