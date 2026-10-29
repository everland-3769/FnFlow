import Foundation
import ApplicationServices
import IOKit
import Combine
import Carbon
import AppKit

enum FnMode: Int, Codable, CaseIterable, Identifiable {
    case media = 0
    case standard = 1
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .media:
            return String(localized: "Media")
        case .standard:
            return String(localized: "Standard F1-F12")
        }
    }
}


// C symbol binding for IOHIDSetParameter
@_silgen_name("IOHIDSetParameter")
private func IOHIDSetParameter(
    _ handle: io_connect_t,
    _ key: CFString,
    _ bytes: UnsafeRawPointer,
    _ size: IOByteCount
) -> kern_return_t

class KeyboardManager: ObservableObject {
    static let shared = KeyboardManager()
    
    @Published private(set) var currentMode: FnMode = .media
    @Published var isAccessibilityGranted: Bool = false
    
    private let key = "com.apple.keyboard.fnState" as CFString
    private var hotKeyRef: EventHotKeyRef?
    
    init() {
        self.currentMode = readCurrentMode()
        checkAccessibilityPermission()
        setupGlobalHotkey()
    }
    
    @discardableResult
    func checkAccessibilityPermission() -> Bool {
        let isTrusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.isAccessibilityGranted = isTrusted
        }
        return isTrusted
    }
    
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func readCurrentMode() -> FnMode {
        guard let value = CFPreferencesCopyAppValue(key, kCFPreferencesAnyApplication) as? Bool else {
            return .media
        }
        return value ? .standard : .media
    }
    
    func toggleMode() -> FnMode {
        let newMode: FnMode = (currentMode == .media) ? .standard : .media
        setMode(newMode)
        return newMode
    }
    
    func setMode(_ mode: FnMode) {
        DispatchQueue.main.async {
            if self.currentMode != mode {
                self.currentMode = mode
            }
        }
        
        let isStandard = (mode == .standard)
        let value: CFBoolean = isStandard ? kCFBooleanTrue : kCFBooleanFalse
        
        // Write global preference
        CFPreferencesSetValue(key, value, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        
        // Write directly to IOHIDSystem
        updateHIDFKeyMode(isStandard: isStandard)
        
        // Post distributed notification
        let notificationName = CFNotificationName("com.apple.keyboard.fnStateChanged" as CFString)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDistributedCenter(),
            notificationName,
            nil,
            nil,
            true
        )
    }
    
    private func updateHIDFKeyMode(isStandard: Bool) {
        let masterPort = kIOMainPortDefault
        let matching = IOServiceMatching("IOHIDSystem")
        let service = IOServiceGetMatchingService(masterPort, matching)
        
        if service != 0 {
            var connect: io_connect_t = 0
            if IOServiceOpen(service, mach_task_self_, 1, &connect) == KERN_SUCCESS {
                var val: UInt32 = isStandard ? 1 : 0
                _ = IOHIDSetParameter(connect, "HIDFKeyMode" as CFString, &val, IOByteCount(MemoryLayout<UInt32>.size))
                IOServiceClose(connect)
            }
            IOObjectRelease(service)
        }
    }
    
    // MARK: - Carbon Global Hotkey (Option + F)
    private func setupGlobalHotkey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x466E466C), id: 1) // "FnFl"
        let modifierFlags: UInt32 = UInt32(optionKey)
        let keyCode: UInt32 = 3 // Keycode for 'F'
        
        // 直接傳入 hotKeyID 常量即可消除警告
        RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (_, _, _) -> OSStatus in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .fnFlowTriggerGlobalHotkey, object: nil)
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }
}

extension Notification.Name {
    static let fnFlowTriggerGlobalHotkey = Notification.Name("fnFlowTriggerGlobalHotkey")
}
