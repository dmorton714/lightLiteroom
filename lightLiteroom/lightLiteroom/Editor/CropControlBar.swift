import SwiftUI

/// Fixed, non-draggable bar shown while cropping: aspect-ratio presets plus
/// Cancel/Done. Deliberately simpler than `AdjustmentsPanelView` — crop
/// mode hides that panel rather than layering a second floating surface on
/// top of it (see `ContentView+Layout`).
struct CropControlBar: View {
    @Binding var aspect: CropAspectRatio
    let onCancel: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Glass.spacing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Glass.compactSpacing) {
                    ForEach(CropAspectRatio.allCases, id: \.self) { option in
                        Button(option.displayName) { aspect = option }
                            .buttonStyle(.glass)
                            .font(.caption.weight(.medium))
                            .opacity(aspect == option ? 1 : 0.6)
                    }
                }
            }
            HStack {
                Button("Cancel", role: .cancel, action: onCancel)
                    .buttonStyle(.plain)
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.plain)
                    .fontWeight(.semibold)
            }
        }
        .padding(Glass.spacing)
        .foregroundStyle(.white)
        .darkDock()
        .padding(.horizontal, Glass.screenEdgePadding)
        .padding(.bottom, Glass.compactSpacing)
    }
}
