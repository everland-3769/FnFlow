import Cocoa
import Combine
import UniformTypeIdentifiers

enum AppRule: String, Codable, CaseIterable {
    case useGlobal = "Default"
    case media = "Media"
    case standard = "Standard"
}

struct AppRuleItem: Identifiable {
    let id: String
    let name: String
    let bundleId: String
    let icon: NSImage?
    let rule: AppRule
}

class AppMonitor: ObservableObject {
    @Published var currentApp: NSRunningApplication?
    
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
    
    @Published var globalDefaultMode: FnMode = .media {
        didSet {
            UserDefaults.standard.set(globalDefaultMode.rawValue, forKey: "GlobalFnMode")
            applyRuleForCurrentApp()
        }
    }
    
    @Published var appRules: [String: AppRule] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(appRules) {
                UserDefaults.standard.set(data, forKey: "AppRules")
            }
            applyRuleForCurrentApp()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
        setupWorkspaceObserver()
    }
    
    private func loadSettings() {
        if UserDefaults.standard.object(forKey: "IsEnabled") != nil {
            self.isEnabled = UserDefaults.standard.bool(forKey: "IsEnabled")
        }
        if UserDefaults.standard.object(forKey: "LaunchAtLogin") != nil {
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "LaunchAtLogin")
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
    
    func applyRuleForCurrentApp() {
        guard isEnabled else { return }
        
        guard let bundleId = currentApp?.bundleIdentifier else {
            KeyboardManager.shared.setMode(globalDefaultMode)
            return
        }
        
        let rule = appRules[bundleId] ?? .useGlobal
        switch rule {
        case .useGlobal:
            KeyboardManager.shared.setMode(globalDefaultMode)
        case .media:
            KeyboardManager.shared.setMode(.media)
        case .standard:
            KeyboardManager.shared.setMode(.standard)
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
