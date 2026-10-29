import SwiftUI

@main
struct FnFlowApp: App {
    @StateObject private var monitor = AppMonitor()
    @StateObject private var keyboardManager = KeyboardManager.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuView(monitor: monitor)
                .onOpenURL { url in
                    handleURLScheme(url)
                }
        } label: {
            HStack(spacing: 5) {
                // 1. 旋轉動畫狀態 (切換模式時的暫態提示)
                if monitor.isMenuBarAnimating {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .symbolEffect(.rotate, value: monitor.isMenuBarAnimating)
                } else {
                    // 2. 根據設定的外觀風格動態渲染選單列圖示 (Standard / Minimal / Text Only)
                    switch monitor.menuBarIconStyle {
                    case .standard:
                        Image(systemName: monitor.isEnabled
                              ? (keyboardManager.currentMode == .standard ? "fn" : "sun.max.fill")
                              : "slash.circle")
                    case .minimal:
                        Image(systemName: monitor.isEnabled
                              ? (keyboardManager.currentMode == .standard ? "f.circle.fill" : "circle.fill")
                              : "circle.slash")
                    case .textOnly:
                        Text(monitor.isEnabled
                             ? (keyboardManager.currentMode == .standard ? "F1-F12" : "Media")
                             : "Off")
                            .font(.system(size: 11, weight: .bold))
                    }
                }
                
                // 3. 暫態文字提示 (若選擇 MenuBar 提示風格時跳出)
                if let feedbackText = monitor.transientMenuBarText {
                    Text(feedbackText)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
        }
        .menuBarExtraStyle(.window)
        
        Window("FnFlow Settings", id: "settings-window") {
            SettingsView(monitor: monitor)
        }
        .windowResizability(.contentSize)
    }
    
    // MARK: - 解析 fnflow:// 協議指令
    private func handleURLScheme(_ url: URL) {
        guard url.scheme?.lowercased() == "fnflow" else { return }
        
        let host = url.host?.lowercased()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        switch host {
        case "toggle":
            monitor.isEnabled.toggle()
            
        case "set-mode":
            if let modeValue = queryItems.first(where: { $0.name == "mode" })?.value?.lowercased() {
                if modeValue == "standard" || modeValue == "f1-f12" {
                    KeyboardManager.shared.setMode(.standard)
                } else if modeValue == "media" {
                    KeyboardManager.shared.setMode(.media)
                }
            }
            
        case "set-enabled":
            if let enabledValue = queryItems.first(where: { $0.name == "value" })?.value?.lowercased() {
                monitor.isEnabled = (enabledValue == "true" || enabledValue == "1")
            }
            
        default:
            break
        }
    }
}

// MARK: - 選單列快顯面板視圖
struct MenuView: View {
    @ObservedObject var monitor: AppMonitor
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // 1. 全域預設模式
            HStack {
                Text("Default Mode")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                
                LiquidGlassControl(
                    selection: $monitor.globalDefaultMode,
                    options: [
                        (tag: FnMode.media, icon: "sun.max.fill", label: nil),
                        (tag: FnMode.standard, icon: "fn", label: nil)
                    ]
                )
                .frame(width: 90)
            }
            .padding(.horizontal, 4)
            
            Divider()
            
            // 2. 目前前景 App 狀態列
            if let app = monitor.currentApp {
                HStack(spacing: 12) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "app.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.localizedName ?? "Unknown Application")
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                        
                        let currentBundleId = app.bundleIdentifier ?? ""
                        let currentRule = monitor.appRules[currentBundleId] ?? .useGlobal
                        
                        LiquidGlassControl(
                            selection: Binding(
                                get: { currentRule },
                                set: { monitor.setRuleForCurrentApp($0) }
                            ),
                            options: [
                                (tag: AppRule.useGlobal, icon: "equal", label: nil),
                                (tag: AppRule.media, icon: "sun.max.fill", label: nil),
                                (tag: AppRule.standard, icon: "fn", label: nil)
                            ]
                        )
                        .frame(width: 120)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
            }
            
            Divider()
            
            // 3. 狀態切換開關區塊
            VStack(spacing: 2) {
                MenuToggleRow(
                    icon: "power",
                    title: "Disable FnFlow",
                    isOn: Binding(
                        get: { !monitor.isEnabled },
                        set: { monitor.isEnabled = !$0 }
                    )
                )
                
                MenuToggleRow(
                    icon: "checkmark.circle",
                    title: "Launch at Login",
                    isOn: $monitor.launchAtLogin
                )
            }
            
            Divider()
            
            // 4. 系統設定與結束區塊
            VStack(spacing: 2) {
                MenuActionButton(icon: "gearshape", title: "Settings...", shortcut: "⌘ ,") {
                    openSettingsWindow()
                }
                
                MenuActionButton(icon: "power.circle", title: "Quit", shortcut: "⌘ Q") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(12)
        .frame(width: 240)
    }
    
    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings-window")
    }
}

// MARK: - 自訂按鈕元件
struct MenuActionButton: View {
    let icon: String
    let title: LocalizedStringKey
    var shortcut: String? = nil
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(isHovered ? .primary : .secondary)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
            .background(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovered = hover
        }
    }
}

// MARK: - 自訂 Toggle 元件
struct MenuToggleRow: View {
    let icon: String
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(isOn ? .accentColor : (isHovered ? .primary : .secondary))
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
            .background(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovered = hover
        }
    }
}
