import SwiftUI

/// Uniform toolbar glyph so every dock button has the same hit box.
struct DockIcon: View {
    static let size: CGFloat = 22
    static let hitSize: CGFloat = 36
    let systemName: String

    init(_ systemName: String) {
        self.systemName = systemName
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .frame(width: Self.hitSize, height: Self.hitSize)
    }
}

struct DockDivider: View {
    var body: some View {
        Divider()
            .frame(height: 20)
            .overlay(.white.opacity(0.25))
    }
}
