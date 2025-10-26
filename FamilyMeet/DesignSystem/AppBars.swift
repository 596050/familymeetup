import SwiftUI

// MARK: - Bar Tokens

public enum FMBarPad {
    // Global bar paddings used across the app
    public static let horizontal: CGFloat = 8
    public static let vertical: CGFloat = 2
    public static let bottomBase: CGFloat = 6
}

// MARK: - Top Bar

public struct FMTopBar<Leading: View, Title: View, Trailing: View>: View {
    var leading: (() -> Leading)?
    var title: () -> Title
    var trailing: (() -> Trailing)?

    public init(leading: (() -> Leading)? = nil,
                title: @escaping () -> Title,
                trailing: (() -> Trailing)? = nil) {
        self.leading = leading
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack {
            Group { if let leading { leading() } else { Color.clear.frame(width: 1, height: 1).opacity(0) } }
            Spacer(minLength: 8)
            Group { title() }
            Spacer(minLength: 8)
            Group { if let trailing { trailing() } else { Color.clear.frame(width: 1, height: 1).opacity(0) } }
        }
        .padding(.horizontal, FMBarPad.horizontal)
        .padding(.vertical, FMBarPad.vertical)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Bottom Bar

public struct FMBottomBar<Content: View>: View {
    var keyboardAware: Bool
    @ViewBuilder var content: () -> Content
    @StateObject private var keyboard = KeyboardObserver()

    public init(keyboardAware: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.keyboardAware = keyboardAware
        self.content = content
    }

    public var body: some View {
        content()
            .padding(.horizontal, FMBarPad.horizontal)
            .padding(.bottom, FMBarPad.bottomBase + (keyboardAware ? keyboard.bottomInset : 0))
            .background(.ultraThinMaterial)
    }
}
