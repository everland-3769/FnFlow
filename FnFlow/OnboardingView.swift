import SwiftUI
import AppKit
import Combine

struct OnboardingView: View {
    @ObservedObject var monitor: AppMonitor
    @Binding var isPresented: Bool
    @State private var currentStep: Int = 0
    @State private var isAccessibilityGranted: Bool = KeyboardManager.shared.checkAccessibilityPermission()
    @Environment(\.colorScheme) private var colorScheme
    
    // 定時器監聽輔助使用權限授權狀態
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            // 頂部分頁進度條
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.accentColor : Color.primary.opacity(0.12))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.25), value: currentStep)
                }
            }
            .padding(.top, 8)
            
            // 分頁內容轉換
            Group {
                switch currentStep {
                case 0:
                    welcomeStepView
                case 1:
                    permissionStepView
                case 2:
                    preferencesStepView
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
            
            Spacer()
            
            // 底部控制按鈕
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < 2 {
                    Button("Continue") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(width: 480, height: 380)
        .onReceive(timer) { _ in
            isAccessibilityGranted = KeyboardManager.shared.checkAccessibilityPermission()
        }
    }
    
    // 步驟 1：歡迎頁面（型別修正為 some View）
    private var welcomeStepView: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)
                .padding(.top, 10)
            
            Text("Welcome to FnFlow")
                .font(.system(size: 22, weight: .bold))
            
            Text("FnFlow automatically switches your F1–F12 keys between Media Keys and Standard Function Keys based on your active app.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    // 步驟 2：輔助使用權限授權頁面（型別修正為 some View）
    private var permissionStepView: some View {
        VStack(spacing: 16) {
            Image(systemName: isAccessibilityGranted ? "checkmark.seal.fill" : "lock.shield.fill")
                .font(.system(size: 52))
                .foregroundColor(isAccessibilityGranted ? .green : .orange)
                .padding(.top, 10)
            
            Text("Accessibility Permission")
                .font(.system(size: 20, weight: .bold))
            
            Text("macOS requires Accessibility permission to detect key events and frontmost application switches.")
                .font(.system(size: 12.5))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
            
            HStack(spacing: 12) {
                if isAccessibilityGranted {
                    Label("Permission Granted", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 13, weight: .semibold))
                } else {
                    Button("Grant Accessibility Permission") {
                        KeyboardManager.shared.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .padding(.top, 8)
        }
    }
    
    // 步驟 3：快速偏好設定頁面（型別修正為 some View）
    private var preferencesStepView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Initial Configuration")
                .font(.system(size: 18, weight: .bold))
                .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Global Default Behavior")
                            .font(.system(size: 13, weight: .medium))
                        Text("Mode used when no app rules apply")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Picker("", selection: $monitor.globalDefaultMode) {
                        Text("Media Keys").tag(FnMode.media)
                        Text("Standard F1-F12").tag(FnMode.standard)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                
                Divider()
                
                Toggle(isOn: $monitor.launchAtLogin) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch FnFlow at Login")
                            .font(.system(size: 13, weight: .medium))
                        Text("Automatically start in menu bar when macOS boots")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(10)
        }
    }
}
