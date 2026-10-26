import SwiftUI

@main
struct FnFlowApp: App {
    @StateObject private var monitor = AppMonitor()
    @StateObject private var keyboardManager = KeyboardManager.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuView(monitor: monitor)
        } label: {
            Image(systemName: monitor.isEnabled
                  ? (keyboardManager.currentMode == .standard ? "fn" : "sun.max.fill")
                  : "slash.circle")
        }
        .menuBarExtraStyle(.window)
        
        Window("FnFlow Settings", id: "settings-window") {
            SettingsView(monitor: monitor)
        }
        .windowResizability(.contentSize)
    }
}

// MARK: - Menu Bar Popover View
struct MenuView: View {
    @ObservedObject var monitor: AppMonitor
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Global default mode switcher
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
            
            // Active application status and rule switcher
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
            
            // Preferences and app controls
            VStack(spacing: 2) {
                MenuActionButton(icon: "gearshape", title: "Settings...", shortcut: "⌘ ,") {
                    openSettingsWindow()
                }
                
                MenuToggleRow(icon: "checkmark.circle", title: "Launch at Login", isOn: $monitor.launchAtLogin)
                
                MenuToggleRow(icon: "power", title: "Disable FnFlow", isOn: Binding(
                    get: { !monitor.isEnabled },
                    set: { monitor.isEnabled = !$0 }
                ))
            }
            
            Divider()
            
            // System actions
            VStack(spacing: 2) {
                MenuActionButton(icon: "info.circle", title: "About FnFlow") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel(nil)
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

// MARK: - Menu Action Button Component
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

// MARK: - Menu Toggle Row Component
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
