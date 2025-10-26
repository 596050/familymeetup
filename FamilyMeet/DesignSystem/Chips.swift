import SwiftUI

public struct FMChip: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    public init(_ title: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.selected = selected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(background)
                .foregroundStyle(foreground)
                .overlay(Capsule().stroke(Color.black.opacity(0.06)))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var background: some ShapeStyle {
        selected ? FMColor.brand.opacity(0.18) : Color(.secondarySystemBackground)
    }

    private var foreground: Color { selected ? FMColor.brand : .primary }
}

public struct FMChipGroup: View {
    var options: [String]
    @Binding var selection: Set<String>
    var allowsMultipleSelection: Bool

    public init(options: [String], selection: Binding<Set<String>>, allowsMultipleSelection: Bool = true) {
        self.options = options
        self._selection = selection
        self.allowsMultipleSelection = allowsMultipleSelection
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.self) { opt in
                FMChip(opt, selected: selection.contains(opt)) {
                    if allowsMultipleSelection {
                        if selection.contains(opt) { selection.remove(opt) } else { selection.insert(opt) }
                    } else {
                        selection = [opt]
                    }
                }
            }
        }
    }
}

