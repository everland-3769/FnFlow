import Cocoa
import Combine
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

// MARK: - 選單列圖示風格 Enum
enum MenuBarIconStyle: String, Codable, CaseIterable, Identifiable {
    case standard = "Standard Icon"
    case minimal = "Minimal Icon"
    case textOnly = "Text Only"
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .standard: return "Standard Icon (Sun / Fn)"
        case .minimal: return "Minimal Dot Icon"
        case .textOnly: return "Text Label Only"
        }
    }
}

enum AppRule: String, Codable, CaseIterable {
    case useGlobal = "Default"
    case media = "Media"
    case standard = "Standard"
    
    var title: LocalizedStringKey {
        switch self {
        case .useGlobal: return "Default Mode"
        case .media: return "Media Keys"
        case .standard: return "Standard F1 - F12 Keys"
        }
    }
}

struct AppRuleItem: Identifiable {
    let id: String
    let name: String
    let bundleId: String
    let icon: NSImage?
    let rule: AppRule
}

// MARK: - 可備份與同步的 JSON 資料結構
struct FnFlowConfigData: Codable {
    let version: String
    let globalDefaultMode: Int
    let appRules: [String: AppRule]
    let menuBarIconStyle: String
    let notificationStyle: String
}

class AppMonitor: ObservableObject {
    @Published var currentApp: NSRunningApplication?
    
    // 選單列暫態提示狀態
    @Published var transientMenuBarText: String? = nil
    @Published var isMenuBarAnimating: Bool = false
    private var menuBarFeedbackTimer: Timer?
    
    @Published var isEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "IsEnabled")
            applyRuleForCurrentApp()
        }
    }
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "LaunchAtLogin")
        }
    }
    
    @Published var enableGlobalHotkey: Bool = true {
        didSet {
            UserDefaults.standard.set(enableGlobalHotkey, forKey: "EnableGlobalHotkey")
        }
    }
    
    @Published var menuBarIconStyle: MenuBarIconStyle = .standard {
        didSet {
            UserDefaults.standard.set(menuBarIconStyle.rawValue, forKey: "MenuBarIconStyle")
            syncToiCloud()
        }
    }
    
    @Published var notificationStyle: NotificationStyle = .osd {
        didSet {
            UserDefaults.standard.set(notificationStyle.rawValue, forKey: "NotificationStyle")
            if notificationStyle == .systemBanner {
                requestNotificationPermission()
            }
            syncToiCloud()
        }
    }
    
    @Published var osdPosition: OSDPosition = .bottom {
        didSet {
            UserDefaults.standard.set(osdPosition.rawValue, forKey: "OSDPosition")
        }
    }
    
    @Published var globalDefaultMode: FnMode = .media {
        didSet {
            UserDefaults.standard.set(globalDefaultMode.rawValue, forKey: "GlobalFnMode")
            applyRuleForCurrentApp()
            syncToiCloud()
        }
    }
    
    @Published var appRules: [String: AppRule] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(appRules) {
                UserDefaults.standard.set(data, forKey: "AppRules")
            }
            applyRuleForCurrentApp()
            syncToiCloud()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
        setupWorkspaceObserver()
        setupHotkeyObserver()
        setupiCloudObserver()
    }
    
    private func loadSettings() {
        if UserDefaults.standard.object(forKey: "IsEnabled") != nil {
            self.isEnabled = UserDefaults.standard.bool(forKey: "IsEnabled")
        }
        if UserDefaults.standard.object(forKey: "LaunchAtLogin") != nil {
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "LaunchAtLogin")
        }
        if UserDefaults.standard.object(forKey: "EnableGlobalHotkey") != nil {
            self.enableGlobalHotkey = UserDefaults.standard.bool(forKey: "EnableGlobalHotkey")
        } else {
            self.enableGlobalHotkey = true
        }
        if let rawIconStyle = UserDefaults.standard.string(forKey: "MenuBarIconStyle"),
           let style = MenuBarIconStyle(rawValue: rawIconStyle) {
            self.menuBarIconStyle = style
        }
        if let rawStyle = UserDefaults.standard.string(forKey: "NotificationStyle"),
           let style = NotificationStyle(rawValue: rawStyle) {
            self.notificationStyle = style
        } else {
            self.notificationStyle = .osd
        }
        if let rawPos = UserDefaults.standard.string(forKey: "OSDPosition"),
           let pos = OSDPosition(rawValue: rawPos) {
            self.osdPosition = pos
        } else {
            self.osdPosition = .bottom
        }
        if let rawMode = UserDefaults.standard.object(forKey: "GlobalFnMode") as? Int,
           let mode = FnMode(rawValue: rawMode) {
            self.globalDefaultMode = mode
        }
        if let data = UserDefaults.standard.data(forKey: "AppRules"),
           let rules = try? JSONDecoder().decode([String: AppRule].self, from: data) {
            self.appRules = rules
        }
    }
    
    // MARK: - iCloud 同步機制
    private func setupiCloudObserver() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.loadFromiCloud()
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private func syncToiCloud() {
        let iCloudStore = NSUbiquitousKeyValueStore.default
        if let data = try? JSONEncoder().encode(appRules) {
            iCloudStore.set(data, forKey: "iCloud_AppRules")
        }
        iCloudStore.set(globalDefaultMode.rawValue, forKey: "iCloud_GlobalFnMode")
        iCloudStore.synchronize()
    }
    
    private func loadFromiCloud() {
        let iCloudStore = NSUbiquitousKeyValueStore.default
        if let data = iCloudStore.data(forKey: "iCloud_AppRules"),
           let rules = try? JSONDecoder().decode([String: AppRule].self, from: data) {
            DispatchQueue.main.async {
                self.appRules = rules
            }
        }
        let rawMode = iCloudStore.longLong(forKey: "iCloud_GlobalFnMode")
        if let mode = FnMode(rawValue: Int(rawMode)) {
            DispatchQueue.main.async {
                self.globalDefaultMode = mode
            }
        }
    }
    
    // MARK: - JSON 設定檔匯入與匯出 (Import / Export)
    func exportConfiguration() {
        let config = FnFlowConfigData(
            version: "1.0.0",
            globalDefaultMode: globalDefaultMode.rawValue,
            appRules: appRules,
            menuBarIconStyle: menuBarIconStyle.rawValue,
            notificationStyle: notificationStyle.rawValue
        )
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "FnFlow_Backup.json"
        
        if panel.runModal() == .OK, let url = panel.url {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(config) {
                try? data.write(to: url)
            }
        }
    }
    
    func importConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url),
               let config = try? JSONDecoder().decode(FnFlowConfigData.self, from: data) {
                if let mode = FnMode(rawValue: config.globalDefaultMode) {
                    self.globalDefaultMode = mode
                }
                if let iconStyle = MenuBarIconStyle(rawValue: config.menuBarIconStyle) {
                    self.menuBarIconStyle = iconStyle
                }
                if let notifStyle = NotificationStyle(rawValue: config.notificationStyle) {
                    self.notificationStyle = notifStyle
                }
                self.appRules = config.appRules
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }
    
    private func setupWorkspaceObserver() {
        self.currentApp = NSWorkspace.shared.frontmostApplication
        self.applyRuleForCurrentApp()
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .filter { $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .sink { [weak self] app in
                DispatchQueue.main.async {
                    self?.currentApp = app
                    self?.applyRuleForCurrentApp()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupHotkeyObserver() {
        NotificationCenter.default.publisher(for: .fnFlowTriggerGlobalHotkey)
            .sink { [weak self] _ in
                guard let self = self, self.isEnabled, self.enableGlobalHotkey else { return }
                let newMode: FnMode = (self.globalDefaultMode == .media) ? .standard : .media
                self.globalDefaultMode = newMode
                self.triggerNotificationFeedback(for: self.currentApp, targetMode: newMode)
            }
            .store(in: &cancellables)
    }
    
    func applyRuleForCurrentApp() {
        guard isEnabled else { return }
        
        guard let bundleId = currentApp?.bundleIdentifier else {
            KeyboardManager.shared.setMode(globalDefaultMode)
            return
        }
        
        let rule = appRules[bundleId] ?? .useGlobal
        let targetMode: FnMode
        
        switch rule {
        case .useGlobal:
            targetMode = globalDefaultMode
        case .media:
            targetMode = .media
        case .standard:
            targetMode = .standard
        }
        
        KeyboardManager.shared.setMode(targetMode)
        
        if targetMode != globalDefaultMode {
            triggerNotificationFeedback(for: currentApp, targetMode: targetMode)
        }
    }
    
    private func triggerNotificationFeedback(for app: NSRunningApplication?, targetMode: FnMode) {
        let appName = app?.localizedName ?? String(localized: "Application")
        
        switch notificationStyle {
        case .disabled:
            break
        case .osd:
            OSDHUDManager.shared.show(appName: appName, icon: app?.icon, mode: targetMode, position: osdPosition)
        case .menuBar:
            menuBarFeedbackTimer?.invalidate()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isMenuBarAnimating = true
                self.transientMenuBarText = targetMode.title
                
                self.menuBarFeedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    withAnimation {
                        self.isMenuBarAnimating = false
                        self.transientMenuBarText = nil
                    }
                }
            }
        case .systemBanner:
            let content = UNMutableNotificationContent()
            content.title = appName
            let modeText = targetMode.title
            let formatString = String(localized: "Switched to %@", comment: "Notification body when switching Fn mode")
            content.body = String(format: formatString, modeText)
            let request = UNNotificationRequest(
                identifier: "FnFlow-ModeSwitch-\(app?.bundleIdentifier ?? UUID().uuidString)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        case .soundOnly:
            NSSound(named: "Pop")?.play()
        }
    }
    
    func setRuleForCurrentApp(_ rule: AppRule) {
        guard let bundleId = currentApp?.bundleIdentifier else { return }
        setRule(rule, for: bundleId)
    }
    
    func setRule(_ rule: AppRule, for bundleId: String) {
        if rule == .useGlobal {
            appRules.removeValue(forKey: bundleId)
        } else {
            appRules[bundleId] = rule
        }
    }
    
    func getCustomizedAppItems() -> [AppRuleItem] {
        return appRules.map { (bundleId, rule) in
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first
            let appName = running?.localizedName ?? bundleId.components(separatedBy: ".").last ?? bundleId
            let icon = running?.icon ?? NSWorkspace.shared.icon(forFile: "/Applications")
            return AppRuleItem(id: bundleId, name: appName, bundleId: bundleId, icon: icon, rule: rule)
        }
    }
    
    func getRunningAppItems() -> [AppRuleItem] {
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier else { return nil }
                let name = app.localizedName ?? bundleId
                let icon = app.icon
                let currentRule = appRules[bundleId] ?? .useGlobal
                return AppRuleItem(id: bundleId, name: name, bundleId: bundleId, icon: icon, rule: currentRule)
            }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    func selectAndAddApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
                setRule(.standard, for: bundleId)
            }
        }
    }
}
