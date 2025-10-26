import SwiftUI

public enum FMToastStyle { case success, info, warning, error }

public struct FMToastItem: Identifiable, Equatable {
    public let id = UUID()
    public var message: String
    public var style: FMToastStyle = .info
    public var duration: TimeInterval = 2.0
}

public struct FMToast: View {
    var item: FMToastItem

    public init(item: FMToastItem) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
            Text(item.message).multilineTextAlignment(.leading)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .foregroundStyle(.white)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
        .padding(.horizontal, 16)
    }

    private var background: some ShapeStyle {
        switch item.style {
        case .success: return Color.green
        case .info: return Color.gray
        case .warning: return Color.orange
        case .error: return Color.red
        }
    }

    private var iconName: String {
        switch item.style {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}

public struct FMToastHost: ViewModifier {
    @Binding var item: FMToastItem?
    @State private var isVisible: Bool = false

    public func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let item {
                FMToast(item: item)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 24)
                    .onAppear { scheduleAutoDismiss(item) }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: item)
    }

    private func scheduleAutoDismiss(_ item: FMToastItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + item.duration) {
            withAnimation { self.item = nil }
        }
    }
}

public extension View {
    func fmToast(item: Binding<FMToastItem?>) -> some View {
        modifier(FMToastHost(item: item))
    }
}

