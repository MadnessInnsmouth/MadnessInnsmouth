using System;
using System.Linq;
using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

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
        private float updateInterval = 0.1f;
        private float nextUpdate = 0f;

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

                logger.LogInfo("Accessibility Manager components initialized!");
            }
            catch (Exception ex)
            {
                logger.LogError($"Error initializing Accessibility Manager: {ex}");
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
    }

    /// <summary>
    /// Handles communication with Windows screen readers (NVDA, JAWS, Narrator)
    /// </summary>
    public class ScreenReaderInterface : MonoBehaviour
    {
        private ManualLogSource logger;
        private bool isScreenReaderActive = false;

        public void Initialize(ManualLogSource log)
        {
            logger = log;
            logger.LogInfo("Initializing Screen Reader Interface...");

            try
            {
                // Check if screen reader is running
                isScreenReaderActive = CheckScreenReaderActive();
                
                if (isScreenReaderActive)
                {
                    logger.LogInfo("Screen reader detected and active!");
                }
                else
                {
                    logger.LogWarning("No screen reader detected. Plugin will still function but output may not be heard.");
                }
            }
            catch (Exception ex)
            {
                logger.LogError($"Error initializing Screen Reader Interface: {ex}");
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
                logger?.LogWarning($"Could not check for screen reader: {ex.Message}");
                return false;
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

                // Use Windows SAPI for text-to-speech
                if (isScreenReaderActive || true) // Always try to speak
                {
                    SpeakWithSAPI(text, interrupt);
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
                // Use System.Speech for Windows TTS
                // This will work with NVDA, JAWS, and Narrator
                var type = Type.GetType("System.Speech.Synthesis.SpeechSynthesizer, System.Speech, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35");
                
                if (type != null)
                {
                    dynamic synth = Activator.CreateInstance(type);
                    
                    if (interrupt)
                    {
                        synth.SpeakAsyncCancelAll();
                    }
                    
                    synth.SpeakAsync(text);
                }
                else
                {
                    // Fallback: Just log it
                    logger?.LogInfo($"TTS: {text}");
                }
            }
            catch (Exception ex)
            {
                logger?.LogWarning($"Could not use SAPI TTS: {ex.Message}");
            }
        }
    }

    /// <summary>
    /// Tracks UI elements and makes them accessible
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
            if (eventSystem == null)
            {
                eventSystem = EventSystem.current;
                return;
            }

            try
            {
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
                // Try to get text from various UI components
                var text = obj.GetComponent<Text>();
                if (text != null && !string.IsNullOrEmpty(text.text))
                {
                    return FormatAccessibleText(text.text, obj);
                }

                var tmpText = obj.GetComponent<TMPro.TextMeshProUGUI>();
                if (tmpText != null && !string.IsNullOrEmpty(tmpText.text))
                {
                    return FormatAccessibleText(tmpText.text, obj);
                }

                // Check for button
                var button = obj.GetComponent<Button>();
                if (button != null)
                {
                    // Try to find text in children
                    var childText = obj.GetComponentInChildren<Text>();
                    if (childText != null)
                    {
                        return $"Button: {childText.text}";
                    }
                    
                    var childTMP = obj.GetComponentInChildren<TMPro.TextMeshProUGUI>();
                    if (childTMP != null)
                    {
                        return $"Button: {childTMP.text}";
                    }
                    
                    return $"Button: {obj.name}";
                }

                // Check for toggle
                var toggle = obj.GetComponent<Toggle>();
                if (toggle != null)
                {
                    string state = toggle.isOn ? "checked" : "unchecked";
                    var label = obj.GetComponentInChildren<Text>();
                    if (label != null)
                    {
                        return $"Checkbox {state}: {label.text}";
                    }
                    return $"Checkbox {state}: {obj.name}";
                }

                // Check for input field
                var inputField = obj.GetComponent<InputField>();
                if (inputField != null)
                {
                    return $"Input field: {inputField.placeholder?.GetComponent<Text>()?.text ?? obj.name}. Current value: {inputField.text}";
                }

                // Fallback to object name
                return obj.name;
            }
            catch (Exception ex)
            {
                logger?.LogError($"Error getting accessible name: {ex}");
                return obj.name;
            }
        }

        private string FormatAccessibleText(string text, GameObject obj)
        {
            var button = obj.GetComponent<Button>();
            if (button != null)
            {
                return $"Button: {text}";
            }

            var toggle = obj.GetComponent<Toggle>();
            if (toggle != null)
            {
                string state = toggle.isOn ? "checked" : "unchecked";
                return $"Checkbox {state}: {text}";
            }

            return text;
        }
    }

    /// <summary>
    /// Harmony patches for intercepting Unity UI creation
    /// </summary>
    [HarmonyPatch]
    public static class UIPatches
    {
        // Patch Button.OnEnable to announce when buttons become active
        [HarmonyPatch(typeof(Button), "OnEnable")]
        [HarmonyPostfix]
        public static void Button_OnEnable_Postfix(Button __instance)
        {
            try
            {
                // Make button keyboard navigable
                var selectable = __instance.GetComponent<Selectable>();
                if (selectable != null)
                {
                    selectable.navigation = new Navigation { mode = Navigation.Mode.Automatic };
                }
            }
            catch (Exception ex)
            {
                AccessibilityPlugin.LogError($"Error in Button_OnEnable patch: {ex}");
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
