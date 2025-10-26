import SwiftUI
import UIKit

public struct FMTextField: View {
    public enum FieldKind { case text, secure }

    var title: String
    @Binding var text: String
    var placeholder: String
    var systemImage: String?
    var helper: String?
    var error: String?
    var id: String?
    var kind: FieldKind
    var keyboardType: UIKeyboardType
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization?
    var submitLabel: SubmitLabel?
    var onSubmit: (() -> Void)?

    public init(_ title: String,
                text: Binding<String>,
                placeholder: String = "",
                systemImage: String? = nil,
                helper: String? = nil,
                error: String? = nil,
                id: String? = nil,
                kind: FieldKind = .text,
                keyboardType: UIKeyboardType = .default,
                textContentType: UITextContentType? = nil,
                autocapitalization: TextInputAutocapitalization? = .sentences,
                submitLabel: SubmitLabel? = nil,
                onSubmit: (() -> Void)? = nil) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.systemImage = systemImage
        self.helper = helper
        self.error = error
        self.id = id
        self.kind = kind
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage).foregroundStyle(.secondary) }
                input
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .submitLabel(submitLabel ?? .done)
                .onSubmit { onSubmit?() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous)
                    .fill(FMColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FMRadius.m, style: .continuous)
                    .stroke(error == nil ? Color.black.opacity(0.06) : FMColor.danger.opacity(0.8), lineWidth: 1)
            )

            if let error, !error.isEmpty {
                Text(error).font(.footnote).foregroundStyle(FMColor.danger)
            } else if let helper, !helper.isEmpty {
                Text(helper).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var input: some View {
        if kind == .secure {
            SecureField(placeholder, text: $text)
                .accessibilityIdentifier(id ?? "")
        } else {
            TextField(placeholder, text: $text)
                .accessibilityIdentifier(id ?? "")
        }
    }
}
