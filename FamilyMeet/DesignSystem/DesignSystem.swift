import SwiftUI

// MARK: - Tokens

enum FMColor {
    static let brand = Color.accentColor
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let success = Color.green
    static let danger = Color.red
}

enum FMSpace {
    static let xs: CGFloat = 6
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
}

enum FMRadius {
    static let s: CGFloat = 10
    static let m: CGFloat = 14
    static let l: CGFloat = 20
}

extension View {
    func fmShadowCard() -> some View {
        shadow(color: .black.opacity(0.12), radius: 12, y: 8)
    }
}

// MARK: - Button Styles

struct FMButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, tinted, destructive, success }
    enum Size { case small, medium, large }

    var variant: Variant = .primary
    var size: Size = .medium
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(font(for: size))
            .padding(padding(for: size))
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(background(for: variant, pressed: pressed))
            .foregroundStyle(foreground(for: variant))
            .overlay(border(for: variant))
            .clipShape(RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous))
            .scaleEffect(pressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: pressed)
    }

    private func font(for size: Size) -> Font {
        switch size {
        case .small: return .footnote.weight(.semibold)
        case .medium: return .body.weight(.semibold)
        case .large: return .title3.weight(.semibold)
        }
    }

    private func padding(for size: Size) -> EdgeInsets {
        switch size {
        case .small: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .medium: return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        case .large: return EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        }
    }

    @ViewBuilder
    private func background(for variant: Variant, pressed: Bool) -> some View {
        let opacity: Double = pressed ? 0.85 : 1.0
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous)
                .fill(FMColor.brand.opacity(opacity))
        case .secondary:
            RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous)
                .fill(FMColor.surface.opacity(pressed ? 0.95 : 1.0))
        case .tinted:
            RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous)
                .fill(FMColor.brand.opacity(opacity * 0.15))
        case .destructive:
            RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous)
                .fill(FMColor.danger.opacity(opacity))
        case .success:
            RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous)
                .fill(FMColor.success.opacity(opacity))
        }
    }

    @ViewBuilder
    private func border(for variant: Variant) -> some View {
        switch variant {
        case .secondary, .tinted:
            RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous)
                .stroke(Color.black.opacity(0.06))
        default:
            EmptyView()
        }
    }

    private func foreground(for variant: Variant) -> Color {
        switch variant {
        case .primary, .destructive, .success:
            return .white
        case .secondary:
            return .primary
        case .tinted:
            return FMColor.brand
        }
    }
}

extension Button {
    func fmButton(_ variant: FMButtonStyle.Variant = .primary,
                  size: FMButtonStyle.Size = .medium,
                  fullWidth: Bool = false) -> some View {
        self.buttonStyle(FMButtonStyle(variant: variant, size: size, fullWidth: fullWidth))
    }
}

struct FMIconButtonStyle: ButtonStyle {
    enum Variant { case tinted, primary, success, destructive }
    enum Size { case small, medium, large }

    var variant: Variant = .tinted
    var size: Size = .medium

    func makeBody(configuration: Configuration) -> some View {
        let dim: CGFloat = {
            switch size { case .small: return 28; case .medium: return 36; case .large: return 56 }
        }()
        let pressed = configuration.isPressed
        return configuration.label
            .font(.title3.bold())
            .frame(width: dim, height: dim)
            .foregroundStyle(foreground(for: variant))
            .background(background(for: variant, pressed: pressed))
            .overlay(Circle().stroke(Color.black.opacity(0.06)))
            .clipShape(Circle())
            .scaleEffect(pressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: pressed)
    }

    @ViewBuilder
    private func background(for variant: Variant, pressed: Bool) -> some View {
        switch variant {
        case .tinted:
            Circle().fill(.ultraThinMaterial)
        case .primary:
            Circle().fill(FMColor.brand.opacity(pressed ? 0.85 : 1.0))
        case .success:
            Circle().fill(FMColor.success.opacity(pressed ? 0.85 : 1.0))
        case .destructive:
            Circle().fill(FMColor.danger.opacity(pressed ? 0.85 : 1.0))
        }
    }

    private func foreground(for variant: Variant) -> Color {
        switch variant {
        case .tinted: return .primary
        case .primary, .success, .destructive: return .white
        }
    }
}

// MARK: - Modal Container

struct FMModalContainer<Content: View>: View {
    let title: String
    let onClose: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        NavigationView {
            ScrollView {
                content
                    .padding(.horizontal)
                    .padding(.top)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onClose?() }
                }
            }
        }
    }
}

// MARK: - Menu Row

struct FMMenuRow: View {
    var title: String
    var systemImage: String? = nil
    var subtitle: String? = nil
    var role: ButtonRole? = nil
    var action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: FMSpace.m) {
                if let systemImage { Image(systemName: systemImage) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(.secondary) }
                }
                Spacer()
                if role == nil { Image(systemName: "chevron.right").foregroundStyle(.tertiary) }
            }
        }
        .buttonStyle(FMButtonStyle(variant: role == .destructive ? .destructive : .secondary,
                                   size: .large,
                                   fullWidth: true))
    }
}

// MARK: - Card Helpers

struct FMFullScreenCard<Content: View>: View {
    var color: Color
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle().fill(color.gradient).ignoresSafeArea()
            LinearGradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.45)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            content
                .padding(FMSpace.xl)
                .foregroundStyle(.white)
        }
    }
}

