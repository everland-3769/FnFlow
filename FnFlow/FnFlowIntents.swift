import AppIntents
import SwiftUI

// MARK: - 定義 AppIntent 參數 Enum
enum FnModeAppEnum: String, AppEnum {
    case media = "media"
    case standard = "standard"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Fn Mode"

    static var caseDisplayRepresentations: [FnModeAppEnum: DisplayRepresentation] = [
        .media: "Media Keys",
        .standard: "Standard F1-F12 Keys"
    ]
}

// MARK: - 動作 1：設定 Fn 鍵模式
struct SetFnModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Set FnFlow Mode"
    static var description = IntentDescription("Set FnFlow keyboard mode to Media or Standard F1-F12.")

    @Parameter(title: "Target Mode")
    var mode: FnModeAppEnum

    // 👈 修正點：將 SomeParameterSummary 改為小寫 some 與空格 `some ParameterSummary`
    static var parameterSummary: some ParameterSummary {
        Summary("Set FnFlow mode to \(\.$mode)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let target: FnMode = (mode == .standard) ? .standard : .media
        KeyboardManager.shared.setMode(target)
        return .result()
    }
}

// MARK: - 動作 2：切換 FnFlow 開關狀態
struct ToggleFnFlowIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle FnFlow Auto Switch"
    static var description = IntentDescription("Enable or disable automatic Fn key switching.")

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .fnFlowToggleEnabled, object: nil)
        return .result()
    }
}

extension Notification.Name {
    static let fnFlowToggleEnabled = Notification.Name("fnFlowToggleEnabled")
}

// MARK: - 註冊至 Shortcuts App 預設推薦
struct FnFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetFnModeIntent(),
            phrases: [
                "Set \(.applicationName) mode",
                "Switch \(.applicationName) mode"
            ],
            shortTitle: "Set Keyboard Mode",
            systemImageName: "keyboard"
        )
    }
}
