import SwiftUI
import UIKit

// Shared keyboard observer that reports bottom inset (keyboard overlap)
public final class KeyboardObserver: ObservableObject {
    @Published public var bottomInset: CGFloat = 0

    public init() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            guard let self = self, let info = note.userInfo,
                  let end = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let window = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                        .first else { return }
            let keyboardInWindow = window.convert(end, from: nil)
            let overlap = max(0, window.bounds.maxY - keyboardInWindow.minY)
            self.bottomInset = overlap
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.bottomInset = 0
        }
    }
}

// Adds bottom padding equal to keyboard height + extra buffer
public struct FMKeyboardPadding: ViewModifier {
    @StateObject private var keyboard = KeyboardObserver()
    var extra: CGFloat
    public func body(content: Content) -> some View {
        content.padding(.bottom, keyboard.bottomInset + extra)
    }
}

public extension View {
    func fmKeyboardPadding(_ extra: CGFloat = 0) -> some View { modifier(FMKeyboardPadding(extra: extra)) }
}

// A ScrollView that automatically scrolls the focused field into view
public struct FMFocusableScrollContainer<ID: Hashable, Content: View>: View {
    @Binding var focused: ID?
    var bottomExtra: CGFloat
    @ViewBuilder var content: () -> Content
    @StateObject private var keyboard = KeyboardObserver()

    public init(focused: Binding<ID?>, bottomExtra: CGFloat = 220, @ViewBuilder content: @escaping () -> Content) {
        self._focused = focused
        self.bottomExtra = bottomExtra
        self.content = content
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content()
                    .padding(.bottom, keyboard.bottomInset + bottomExtra)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: focused) { id in
                guard let id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
            .onChange(of: keyboard.bottomInset) { _ in
                if let id = focused { withAnimation { proxy.scrollTo(id, anchor: .center) } }
            }
        }
    }
}

