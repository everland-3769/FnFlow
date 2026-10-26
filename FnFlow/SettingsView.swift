import SwiftUI

struct SettingsView: View {
    @ObservedObject var monitor: AppMonitor
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab(monitor: monitor)
                .tag(0)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            AppRulesSettingsTab(monitor: monitor)
                .tag(1)
                .tabItem {
                    Label("App Rules", systemImage: "app.badge.checkmark")
                }
            
            AboutSettingsTab()
                .tag(2)
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding(20)
        .onAppear {
            updateWindowSize(for: selectedTab, animated: false)
            bringWindowToFront()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            updateWindowSize(for: newValue, animated: true)
        }
    }
    
    // MARK: - Window Resizing Logic
    private func updateWindowSize(for tab: Int, animated: Bool) {
        let targetSize: CGSize
        switch tab {
        case 0:
            targetSize = CGSize(width: 480, height: 350)
        case 1:
            targetSize = CGSize(width: 540, height: 420)
        case 2:
            targetSize = CGSize(width: 460, height: 260)
        default:
            targetSize = CGSize(width: 480, height: 350)
        }
        
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.title.contains("FnFlow") }) {
                let currentFrame = window.frame
                let contentRect = window.contentRect(forFrameRect: currentFrame)
                
                let heightDelta = targetSize.height - contentRect.height
                let widthDelta = targetSize.width - contentRect.width
                
                let newFrame = CGRect(
                    x: currentFrame.origin.x - (widthDelta / 2),
                    y: currentFrame.origin.y - heightDelta,
                    width: currentFrame.size.width + widthDelta,
                    height: currentFrame.size.height + heightDelta
                )
                
                if animated {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.2
                        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                        window.animator().setFrame(newFrame, display: true)
                    }
                } else {
                    window.setFrame(newFrame, display: true)
                }
            }
        }
    }
    
    private func bringWindowToFront() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.title.contains("FnFlow") }) {
                window.level = .floating
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            }
        }
    }
}

// MARK: - Settings Card Group
struct SettingsCardGroup<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsTab: View {
    @ObservedObject var monitor: AppMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General Settings")
                .font(.headline)
            
            SettingsCardGroup {
                SettingsToggleRow(
                    icon: "power",
                    iconColor: .orange,
                    title: "Disable FnFlow",
                    subtitle: "Pause automatic F1-F12 key switching",
                    isOn: Binding(
                        get: { !monitor.isEnabled },
                        set: { monitor.isEnabled = !$0 }
                    )
                )
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsToggleRow(
                    icon: "arrow.clockwise.circle",
                    iconColor: .blue,
                    title: "Launch FnFlow at Login",
                    subtitle: "Automatically run in menu bar when macOS boots",
                    isOn: $monitor.launchAtLogin
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Global Default Mode:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                SettingsCardGroup {
                    ModeCardRow(
                        title: "Media Keys (Volume/Brightness)",
                        subtitle: "Media Keys",
                        icon: "sun.max.fill",
                        isSelected: monitor.globalDefaultMode == .media
                    ) {
                        monitor.globalDefaultMode = .media
                    }
                    
                    Divider()
                        .padding(.leading, 52)
                    
                    ModeCardRow(
                        title: "Standard F1 - F12 Keys",
                        subtitle: "Standard F1-F12",
                        icon: "fn",
                        isSelected: monitor.globalDefaultMode == .standard
                    ) {
                        monitor.globalDefaultMode = .standard
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Mode Card Row
struct ModeCardRow: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Rules Settings Tab
struct AppRulesSettingsTab: View {
    @ObservedObject var monitor: AppMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Application Rules")
                    .font(.headline)
                Spacer()
                Button(action: {
                    monitor.selectAndAddApplication()
                }) {
                    Label("Add Application...", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            let customizedItems = monitor.getCustomizedAppItems()
            
            SettingsCardGroup {
                if customizedItems.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.7))
                        Text("No Application Rules Added")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        Text("All applications will follow the global default behavior.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(customizedItems.enumerated()), id: \.element.id) { index, item in
                                AppRuleRow(item: item, monitor: monitor)
                                
                                if index < customizedItems.count - 1 {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 280)
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - App Rule Row
struct AppRuleRow: View {
    let item: AppRuleItem
    @ObservedObject var monitor: AppMonitor
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .cornerRadius(6)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(item.bundleId)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            LiquidGlassControl(
                selection: Binding(
                    get: { item.rule },
                    set: { newRule in monitor.setRule(newRule, for: item.bundleId) }
                ),
                options: [
                    (tag: AppRule.media, icon: "sun.max.fill", label: nil),
                    (tag: AppRule.standard, icon: "fn", label: nil)
                ]
            )
            .frame(width: 96)
            
            Button(action: {
                monitor.setRule(.useGlobal, for: item.bundleId)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.85))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Remove rule and follow global default")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - About FnFlow Tab
struct AboutSettingsTab: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            HStack(spacing: 20) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 80, height: 80)
                } else {
                    Image(systemName: "keyboard.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("FnFlow")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("Copyright © 2026 FnFlow. All rights reserved.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com")!) {
                    Label("GitHub", systemImage: "star.fill")
                }
                .buttonStyle(.bordered)
                
                Link(destination: URL(string: "mailto:support@fnflow.app")!) {
                    Label("Feedback", systemImage: "paperplane.fill")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
