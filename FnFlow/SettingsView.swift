import SwiftUI

// MARK: - Notification Extension for Tab Switching
extension Notification.Name {
    static let fnFlowOpenSettingsTab = Notification.Name("fnFlowOpenSettingsTab")
}

// MARK: - 側邊欄分頁 Enum (包含 Appearance 外觀分頁)
enum SettingsSidebarTab: Int, CaseIterable, Identifiable {
    case general = 0
    case appearance = 1
    case appRules = 2
    case about = 3
    
    var id: Int { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .general: return "General"
        case .appearance: return "Appearance"
        case .appRules: return "App Rules"
        case .about: return "About"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .appearance: return "paintbrush.fill"
        case .appRules: return "app.badge.checkmark"
        case .about: return "info.circle.fill"
        }
    }
}

// MARK: - 主設定視窗
struct SettingsView: View {
    @ObservedObject var monitor: AppMonitor
    @State private var selectedTab: SettingsSidebarTab = .general
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. 左側選單欄
            SidebarView(selectedTab: $selectedTab)
                .frame(width: 190)
                .background(
                    colorScheme == .dark
                        ? Color.black.opacity(0.3)
                        : Color(NSColor.underPageBackgroundColor)
                )
            
            Divider()
                .opacity(colorScheme == .dark ? 0.2 : 0.12)
            
            // 2. 右側主要內容區
            VStack(alignment: .leading, spacing: 0) {
                Text(selectedTab.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsTab(monitor: monitor)
                    case .appearance:
                        AppearanceSettingsTab(monitor: monitor)
                    case .appRules:
                        AppRulesSettingsTab(monitor: monitor)
                    case .about:
                        AboutSettingsTab()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 650, height: 530)
        .onAppear {
            KeyboardManager.shared.checkAccessibilityPermission()
            bringWindowToFront()
        }
        .onReceive(NotificationCenter.default.publisher(for: .fnFlowOpenSettingsTab)) { notification in
            if let tab = notification.object as? SettingsSidebarTab {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    selectedTab = tab
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

// MARK: - 側邊欄元件
struct SidebarView: View {
    @Binding var selectedTab: SettingsSidebarTab
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(SettingsSidebarTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button(action: {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .accentColor)
                            .frame(width: 22, height: 22)
                            .background(
                                isSelected
                                    ? Color.white.opacity(0.2)
                                    : Color.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.12)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        
                        Text(tab.title)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(isSelected ? Color.accentColor : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 20)
    }
}

// MARK: - 輔助使用權限警告卡片
struct AccessibilityWarningCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Accessibility Permission Needed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Grant permission to enable automatic app switching.")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Grant Permission") {
                KeyboardManager.shared.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.orange)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.22 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.orange.opacity(colorScheme == .dark ? 0.4 : 0.2), lineWidth: 1)
        )
    }
}

// MARK: - 通用設定卡片容器
struct SettingsCardGroup<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(NSColor.controlBackgroundColor).opacity(0.8)
                        : Color.white
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.06),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - 設定開關行
struct SettingsToggleRow: View {
    let icon: String
    var iconColor: Color = .accentColor
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 26, height: 26)
                .background(iconColor.opacity(colorScheme == .dark ? 0.22 : 0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - macOS 外觀風格選項卡片
struct GlobalModeOptionCard: View {
    let icon: String
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            isSelected
                                ? Color.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.12)
                                : Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.03)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
                .frame(width: 96, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isSelected ? Color.accentColor : Color.primary.opacity(0.12),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 全域偏好分頁 (General)
struct GeneralSettingsTab: View {
    @ObservedObject var monitor: AppMonitor
    @ObservedObject var keyboardManager = KeyboardManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                
                if !keyboardManager.isAccessibilityGranted {
                    AccessibilityWarningCard()
                }
                
                // 區塊 1：高頻模式與狀態控制
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mode & Status")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    SettingsCardGroup {
                        SettingsToggleRow(
                            icon: "power",
                            iconColor: .accentColor,
                            title: "Disable FnFlow",
                            subtitle: "Pause automatic F1-F12 key switching",
                            isOn: Binding(
                                get: { !monitor.isEnabled },
                                set: { monitor.isEnabled = !$0 }
                            )
                        )
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 26, height: 26)
                                    .background(Color.accentColor.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Global Default Behavior")
                                        .font(.system(size: 12.5, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("Default mode when no app rules apply")
                                        .font(.system(size: 10.5))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                GlobalModeOptionCard(
                                    icon: "sun.max.fill",
                                    title: "Media Keys",
                                    isSelected: monitor.globalDefaultMode == .media
                                ) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                        monitor.globalDefaultMode = .media
                                    }
                                }
                                
                                GlobalModeOptionCard(
                                    icon: "fn",
                                    title: "Standard F1-F12",
                                    isSelected: monitor.globalDefaultMode == .standard
                                ) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                        monitor.globalDefaultMode = .standard
                                    }
                                }
                                Spacer()
                            }
                            .padding(.leading, 38)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                    }
                }
                
                // 區塊 2：系統與控制
                VStack(alignment: .leading, spacing: 6) {
                    Text("System & Control")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    SettingsCardGroup {
                        SettingsToggleRow(
                            icon: "arrow.clockwise.circle",
                            iconColor: .accentColor,
                            title: "Launch FnFlow at Login",
                            subtitle: "Automatically run in menu bar when macOS boots",
                            isOn: $monitor.launchAtLogin
                        )
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        SettingsToggleRow(
                            icon: "keyboard",
                            iconColor: .accentColor,
                            title: "Global Toggle Shortcut",
                            subtitle: "Press Option + F anywhere to switch modes",
                            isOn: $monitor.enableGlobalHotkey
                        )
                    }
                }
                
                // 區塊 3：備份與 iCloud 同步
                VStack(alignment: .leading, spacing: 6) {
                    Text("Backup & Sync")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    SettingsCardGroup {
                        HStack(spacing: 12) {
                            Image(systemName: "icloud")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .frame(width: 26, height: 26)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("iCloud Rules Sync")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Rules automatically sync across your Mac devices")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Label("Active", systemImage: "checkmark.icloud.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath.circle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .frame(width: 26, height: 26)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Configuration Backup")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Export or import rules as JSON file")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button("Import...") {
                                    monitor.importConfiguration()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Export...") {
                                    monitor.exportConfiguration()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.trailing, 4)
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 外觀分頁 (Appearance)
struct AppearanceSettingsTab: View {
    @ObservedObject var monitor: AppMonitor
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                
                // 區塊 1：提示與反饋 (Notification & Feedback)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notification & Feedback")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    SettingsCardGroup {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .frame(width: 26, height: 26)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notification Style")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(monitor.notificationStyle.subtitle)
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                                    .animation(.easeInOut(duration: 0.15), value: monitor.notificationStyle)
                            }
                            
                            Spacer()
                            
                            Picker("", selection: $monitor.notificationStyle) {
                                ForEach(NotificationStyle.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        
                        if monitor.notificationStyle == .osd {
                            Divider()
                                .padding(.leading, 50)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.split.1x2")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 26, height: 26)
                                    .background(Color.accentColor.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("OSD Position")
                                        .font(.system(size: 12.5, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("Choose where the HUD appears on screen")
                                        .font(.system(size: 10.5))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Picker("", selection: $monitor.osdPosition) {
                                    ForEach(OSDPosition.allCases) { pos in
                                        Text(pos.title).tag(pos)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: monitor.notificationStyle)
                }
                
                // 區塊 2：選單列風格 (Menu Bar Style)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Menu Bar Style")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    SettingsCardGroup {
                        HStack(spacing: 12) {
                            Image(systemName: "menubar.rectangle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .frame(width: 26, height: 26)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Menu Bar Icon Style")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Customize icon appearance in status bar")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Picker("", selection: $monitor.menuBarIconStyle) {
                                ForEach(MenuBarIconStyle.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.trailing, 4)
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - App 規則管理分頁
struct AppRulesSettingsTab: View {
    @ObservedObject var monitor: AppMonitor
    @State private var searchText: String = ""
    @State private var isShowingRunningAppsSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    
                    TextField("Search rules...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(6)
                
                Spacer()
                
                Button(action: {
                    isShowingRunningAppsSheet = true
                }) {
                    Label("Running Apps...", systemImage: "macwindow.on.rectangle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: {
                    monitor.selectAndAddApplication()
                }) {
                    Label("Browse...", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            let allItems = monitor.getCustomizedAppItems()
            let filteredItems = allItems.filter { item in
                searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.bundleId.localizedCaseInsensitiveContains(searchText)
            }
            
            SettingsCardGroup {
                if allItems.isEmpty {
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
                    .padding(.vertical, 48)
                } else if filteredItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 26))
                            .foregroundColor(.secondary.opacity(0.7))
                        Text("No Matching Rules Found")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                AppRuleRow(item: item, monitor: monitor)
                                
                                if index < filteredItems.count - 1 {
                                    Divider()
                                        .padding(.leading, 50)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 330)
                }
            }
        }
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $isShowingRunningAppsSheet) {
            RunningAppsPickerSheet(monitor: monitor)
        }
    }
}

// MARK: - 執行中 App 快速挑選彈出視圖
struct RunningAppsPickerSheet: View {
    @ObservedObject var monitor: AppMonitor
    @Environment(\.dismiss) private var dismiss
    @State private var filterText: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Select Running Application")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("Search running apps...", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(6)
            
            let runningApps = monitor.getRunningAppItems().filter { item in
                filterText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(filterText) ||
                item.bundleId.localizedCaseInsensitiveContains(filterText)
            }
            
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(runningApps) { app in
                        HStack(spacing: 10) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 26, height: 26)
                            } else {
                                Image(systemName: "app.fill")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(app.bundleId)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            LiquidGlassControl(
                                selection: Binding(
                                    get: { monitor.appRules[app.bundleId] ?? .useGlobal },
                                    set: { newRule in monitor.setRule(newRule, for: app.bundleId) }
                                ),
                                options: [
                                    (tag: AppRule.useGlobal, icon: "equal", label: nil),
                                    (tag: AppRule.media, icon: "sun.max.fill", label: nil),
                                    (tag: AppRule.standard, icon: "fn", label: nil)
                                ]
                            )
                            .frame(width: 105)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(8)
                    }
                }
            }
            .frame(height: 280)
        }
        .padding(16)
        .frame(width: 420)
    }
}

// MARK: - App 規則單列
struct AppRuleRow: View {
    let item: AppRuleItem
    @ObservedObject var monitor: AppMonitor
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(6)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.primary)
                Text(item.bundleId)
                    .font(.system(size: 10.5))
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
            .frame(width: 90)
            
            Button(action: {
                monitor.setRule(.useGlobal, for: item.bundleId)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.85))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Remove rule and follow global default")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - 關於分頁 (已完全移除 Sparkle 更新)
struct AboutSettingsTab: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            HStack(spacing: 20) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 76, height: 76)
                } else {
                    Image(systemName: "keyboard.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 68, height: 68)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("FnFlow")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                    
                    Text("Copyright © 2026 FnFlow. All rights reserved.")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/everland-3769/FnFlow")!) {
                    Label("GitHub", systemImage: "star.fill")
                }
                .buttonStyle(.bordered)
                
                Link(destination: URL(string: "mailto:ng930119@gmail.com")!) {
                    Label("Feedback", systemImage: "paperplane.fill")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
