import SwiftUI

// MARK: - Liquid Glass Segmented Control
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
                // Background track
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(colorScheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color(NSColor.controlBackgroundColor).opacity(0.6)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.2)
                                    : Color.black.opacity(0.12),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 2, x: 0, y: 1)
                
                // Active selection indicator
                let indicatorX: CGFloat = {
                    if dragStartIndex != nil {
                        let target = baseOffset + dragTranslation
                        return min(max(target, 0), geometry.size.width - itemWidth)
                    } else {
                        return CGFloat(selectedIndex) * itemWidth
                    }
                }()
                
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                              )
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                              )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.6)
                                    : Color.black.opacity(0.18),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.15),
                        radius: colorScheme == .dark ? 3 : 2,
                        x: 0,
                        y: 1
                    )
                    .frame(width: itemWidth - 4, height: geometry.size.height - 4)
                    .offset(x: indicatorX + 2)
                    .animation(dragStartIndex != nil ? nil : .spring(response: 0.25, dampingFraction: 0.75), value: selection)
                
                // Interactive segment options
                HStack(spacing: 0) {
                    ForEach(0..<options.count, id: \.self) { index in
                        let option = options[index]
                        let isSelected = option.tag == selection
                        
                        HStack(spacing: 4) {
                            Image(systemName: option.icon)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? Color.accentColor : Color.secondary)
                                .scaleEffect(isSelected ? 1.15 : 1.0)
                            
                            if let label = option.label {
                                Text(label)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? Color.primary : Color.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                selection = option.tag
                            }
                        }
                    }
                }
            }
            // Drag gesture handler
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
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            dragTranslation = 0
                            dragStartIndex = nil
                        }
                    }
            )
        }
        .frame(height: 24)
    }
}
