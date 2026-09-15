import SwiftUI

/// Small "Reset" button trailing a section header (Presence, Film, RAW
/// Detail). Unlike `ResetAllButton`, these sections live in a plain
/// `ScrollView`, not a drag-gesture surface, so a plain `Button` needs no
/// gesture workaround.
struct SectionResetButton: View {
    let action: () -> Void

    var body: some View {
        Button("Reset", action: action)
            .buttonStyle(.plain)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}
