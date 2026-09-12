/// One weight per hue band for the 8-channel black and white mixer.
struct BlackAndWhiteMix: Equatable {
    var red = 0.0
    var orange = 0.0
    var yellow = 0.0
    var green = 0.0
    var aqua = 0.0
    var blue = 0.0
    var purple = 0.0
    var magenta = 0.0

    /// Red through magenta in hue order — the kernel's argument order.
    var channels: [Double] { [red, orange, yellow, green, aqua, blue, purple, magenta] }
}

extension AdjustmentSettings {
    var blackAndWhiteMix: BlackAndWhiteMix {
        BlackAndWhiteMix(
            red: bwRedMix, orange: bwOrangeMix, yellow: bwYellowMix, green: bwGreenMix,
            aqua: bwAquaMix, blue: bwBlueMix, purple: bwPurpleMix, magenta: bwMagentaMix
        )
    }

    /// Turns on black and white mode and stamps `mix` into the channel sliders.
    mutating func applyBlackAndWhite(_ mix: BlackAndWhiteMix) {
        isBlackAndWhite = true
        bwRedMix = mix.red
        bwOrangeMix = mix.orange
        bwYellowMix = mix.yellow
        bwGreenMix = mix.green
        bwAquaMix = mix.aqua
        bwBlueMix = mix.blue
        bwPurpleMix = mix.purple
        bwMagentaMix = mix.magenta
    }
}
