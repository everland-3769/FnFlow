import Foundation
import ApplicationServices
import IOKit
import Combine

enum FnMode: Int, Codable {
    case media = 0
    case standard = 1
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
    
    private let key = "com.apple.keyboard.fnState" as CFString
    
    init() {
        self.currentMode = readCurrentMode()
    }
    
    func readCurrentMode() -> FnMode {
        guard let value = CFPreferencesCopyAppValue(key, kCFPreferencesAnyApplication) as? Bool else {
            return .media
        }
        return value ? .standard : .media
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
}
