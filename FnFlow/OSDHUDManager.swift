import SwiftUI
import AppKit

// MARK: - OSD Display Position Enum
enum OSDPosition: String, Codable, CaseIterable, Identifiable {
    case top = "Top"
    case bottom = "Bottom"
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .top: return "Top of Screen"
        case .bottom: return "Bottom of Screen"
        }
    }
}

// MARK: - Notification Style Enum
enum NotificationStyle: String, Codable, CaseIterable, Identifiable {
    case disabled = "Disabled"
    case osd = "OSD"
    case menuBar = "MenuBar"
    case systemBanner = "SystemBanner"
    case soundOnly = "SoundOnly"
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .disabled: return "Disabled"
        case .osd: return "Screen OSD HUD"
        case .menuBar: return "Menu Bar Indicator"
        case .systemBanner: return "System Banner"
        case .soundOnly: return "Sound Effect Only"
        }
    }
    
    // 各提示方式的動態說明文字 (關閉時回覆預設說明)
    var subtitle: LocalizedStringKey {
        switch self {
        case .disabled:
            return "Feedback when switching to custom app rules"
        case .osd:
            return "Show floating OSD HUD capsule on screen"
        case .menuBar:
            return "Temporarily display animation and text in menu bar"
        case .systemBanner:
            return "Send notification banners via macOS Notification Center"
        case .soundOnly:
            return "Play system sound effect when mode switches"
        }
    }
}

// MARK: - Native macOS Floating OSD Manager
class OSDHUDManager {
    static let shared = OSDHUDManager()
    private var panel: NSPanel?
    private var dismissTimer: Timer?
    
    func show(appName: String, icon: NSImage?, mode: FnMode, position: OSDPosition) {
        show(appName: appName, icon: icon, modeName: mode.title, position: position)
    }
    
    func show(appName: String, icon: NSImage?, modeName: String, position: OSDPosition) {
        show(appName: appName, icon: icon, modeTitle: LocalizedStringKey(modeName), position: position)
    }
    
    func show(appName: String, icon: NSImage?, modeTitle: LocalizedStringKey, position: OSDPosition) {
        DispatchQueue.main.async {
            self.dismissTimer?.invalidate()
            
            let hudView = OSDHUDView(appName: appName, icon: icon, modeTitle: modeTitle)
            let hostingView = NSHostingView(rootView: hudView)
            
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            
            let fitSize = hostingView.fittingSize
            let width = max(fitSize.width, 240)
            let height = max(fitSize.height, 68)
            
            if self.panel == nil {
                let panel = NSPanel(
                    contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                panel.isOpaque = false
                panel.backgroundColor = .clear
                panel.hasShadow = false
                panel.level = .floating
                panel.ignoresMouseEvents = true
                panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                self.panel = panel
            }
            
            self.panel?.contentView = hostingView
            self.panel?.setContentSize(NSSize(width: width, height: height))
            
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let x = screenRect.midX - (width / 2)
                let y: CGFloat
                switch position {
                case .top:
                    y = screenRect.maxY - height - 40
                case .bottom:
                    y = screenRect.minY + 70
                }
                self.panel?.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            self.panel?.alphaValue = 1.0
            self.panel?.orderFrontRegardless()
            
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: false) { _ in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    self.panel?.animator().alphaValue = 0.0
                } completionHandler: {
                    self.panel?.orderOut(nil)
                }
            }
        }
    }
}

// MARK: - Liquid Glass OSD View
struct OSDHUDView: View {
    let appName: String
    let icon: NSImage?
    let modeTitle: LocalizedStringKey
    
    init(appName: String, icon: NSImage?, modeTitle: LocalizedStringKey) {
        self.appName = appName
        self.icon = icon
        self.modeTitle = modeTitle
    }
    
    init(appName: String, icon: NSImage?, modeName: String) {
        self.appName = appName
        self.icon = icon
        self.modeTitle = LocalizedStringKey(modeName)
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .cornerRadius(7)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            } else {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 30, height: 30)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(modeTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                          )
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.white.opacity(0.85), Color.white.opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                          )
                )
                .background(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.48), Color.white.opacity(0.12), Color.white.opacity(0.05)]
                            : [Color.white.opacity(0.90), Color.white.opacity(0.40), Color.black.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10),
            radius: 4,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
            radius: 12,
            x: 0,
            y: 6
        )
        .padding(18)
        .fixedSize()
    }
}
