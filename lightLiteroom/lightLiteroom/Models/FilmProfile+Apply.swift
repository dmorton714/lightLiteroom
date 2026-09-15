extension FilmProfile {
    /// Selects this profile at full strength and stamps its finishing
    /// defaults. Every slider stays editable afterward.
    func apply(to settings: inout AdjustmentSettings) {
        settings.filmProfile = self
        settings.filmStrength = self == .none ? 0 : 100
        guard self != .none else { return }

        let data = adjustments
        settings.grainAmount = data.grainAmount
        settings.grainSize = data.grainSize
        settings.fadeAmount = data.fadeAmount
        settings.vignetteAmount = data.vignetteAmount
        if let mix = data.blackAndWhiteMix {
            settings.applyBlackAndWhite(mix)
        }
    }
}
