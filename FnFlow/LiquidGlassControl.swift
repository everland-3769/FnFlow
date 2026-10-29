import SwiftUI

// MARK: - 高對比液態玻璃切換滑桿 (High Contrast Liquid Glass Control)
struct LiquidGlassControl<T: Hashable>: View {
    @Binding var selection: T
    let options: [(tag: T, icon: String, label: LocalizedStringKey?)]
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var dragTranslation: CGFloat = 0
    @State private var dragStartIndex: Int? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let count = CGFloat(options.count)
            let itemWidth = geometry.size.width / count
            let selectedIndex = options.firstIndex(where: { $0.tag == selection }) ?? 0
            
            let activeStartIndex = dragStartIndex ?? selectedIndex
            let baseOffset = CGFloat(activeStartIndex) * itemWidth
            
            ZStack(alignment: .leading) {
                // 1. 底層軌道 ( Track )
                Capsule(style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? AnyShapeStyle(Color.black.opacity(0.45))
                            : AnyShapeStyle(Color.black.opacity(0.08))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.12)
                                    : Color.black.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                
                // 2. 浮動高對比玻璃切換塊 ( Selected Thumb )
                let indicatorX: CGFloat = {
                    if dragStartIndex != nil {
                        let target = baseOffset + dragTranslation
                        return min(max(target, 0), geometry.size.width - itemWidth)
                    } else {
                        return CGFloat(selectedIndex) * itemWidth
                    }
                }()
                
                Capsule(style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.32), Color.white.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                              )
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.white, Color(NSColor.controlBackgroundColor)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                              )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.55)
                                    : Color.black.opacity(0.15),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.12),
                        radius: 3,
                        x: 0,
                        y: 1
                    )
                    .frame(width: itemWidth - 4, height: geometry.size.height - 4)
                    .offset(x: indicatorX + 2)
                    .animation(
                        dragStartIndex != nil ? nil : .spring(response: 0.26, dampingFraction: 0.75),
                        value: selection
                    )
                
                // 3. 切換項目圖示與文字標籤 ( 高對比階層劃分 )
                HStack(spacing: 0) {
                    ForEach(0..<options.count, id: \.self) { index in
                        let option = options[index]
                        let isSelected = option.tag == selection
                        
                        HStack(spacing: 4) {
                            Image(systemName: option.icon)
                                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                // 選中項目為 100% 顯色；未選中項目降至 35% 低對比透明度
                                .foregroundColor(
                                    isSelected
                                        ? Color.primary
                                        : Color.primary.opacity(0.35)
                                )
                                .scaleEffect(isSelected ? 1.12 : 0.95)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                            
                            if let label = option.label {
                                Text(label)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(
                                        isSelected
                                            ? Color.primary
                                            : Color.primary.opacity(0.35)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.75)) {
                                selection = option.tag
                            }
                        }
                    }
                }
            }
            // 4. 吸附手勢處理
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if dragStartIndex == nil {
                            dragStartIndex = selectedIndex
                        }
                        dragTranslation = value.translation.width
                        
                        let currentX = (CGFloat(dragStartIndex!) * itemWidth) + value.translation.width + (itemWidth / 2)
                        let newIndex = min(max(Int(currentX / itemWidth), 0), options.count - 1)
                        
                        let newTag = options[newIndex].tag
                        if newTag != selection {
                            selection = newTag
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.75)) {
                            dragTranslation = 0
                            dragStartIndex = nil
                        }
                    }
            )
        }
        .frame(height: 26)
    }
}
