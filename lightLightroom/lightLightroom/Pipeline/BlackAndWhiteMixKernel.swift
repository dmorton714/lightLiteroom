import CoreImage

/// Hue-weighted luminance kernel behind the 8-channel B&W mixer. Each
/// pixel's hue is split across the two nearest band centers (red=0,
/// orange=30, yellow=60, green=120, aqua=180, blue=240, purple=270,
/// magenta=300) and the mix shift is scaled by saturation so grays stay put.
enum BlackAndWhiteMixKernel {
    static let kernel = CIColorKernel(source: """
        kernel vec4 blackAndWhiteMix(
            __sample pixel,
            float redMix, float orangeMix, float yellowMix, float greenMix,
            float aquaMix, float blueMix, float purpleMix, float magentaMix
        ) {
            float r = pixel.r;
            float g = pixel.g;
            float b = pixel.b;
            float maxc = max(r, max(g, b));
            float minc = min(r, min(g, b));
            float delta = maxc - minc;

            float hue = 0.0;
            if (delta > 0.0001) {
                if (maxc == r) {
                    hue = mod((g - b) / delta, 6.0);
                } else if (maxc == g) {
                    hue = (b - r) / delta + 2.0;
                } else {
                    hue = (r - g) / delta + 4.0;
                }
                hue = hue * 60.0;
                if (hue < 0.0) {
                    hue = hue + 360.0;
                }
            }

            float wRed = 0.0;
            float wOrange = 0.0;
            float wYellow = 0.0;
            float wGreen = 0.0;
            float wAqua = 0.0;
            float wBlue = 0.0;
            float wPurple = 0.0;
            float wMagenta = 0.0;
            if (hue < 30.0) {
                float t = hue / 30.0;
                wRed = 1.0 - t;
                wOrange = t;
            } else if (hue < 60.0) {
                float t = (hue - 30.0) / 30.0;
                wOrange = 1.0 - t;
                wYellow = t;
            } else if (hue < 120.0) {
                float t = (hue - 60.0) / 60.0;
                wYellow = 1.0 - t;
                wGreen = t;
            } else if (hue < 180.0) {
                float t = (hue - 120.0) / 60.0;
                wGreen = 1.0 - t;
                wAqua = t;
            } else if (hue < 240.0) {
                float t = (hue - 180.0) / 60.0;
                wAqua = 1.0 - t;
                wBlue = t;
            } else if (hue < 270.0) {
                float t = (hue - 240.0) / 30.0;
                wBlue = 1.0 - t;
                wPurple = t;
            } else if (hue < 300.0) {
                float t = (hue - 270.0) / 30.0;
                wPurple = 1.0 - t;
                wMagenta = t;
            } else {
                float t = (hue - 300.0) / 60.0;
                wMagenta = 1.0 - t;
                wRed = t;
            }

            float saturation = maxc > 0.0001 ? delta / maxc : 0.0;
            float mixShift = (
                wRed * redMix + wOrange * orangeMix + wYellow * yellowMix + wGreen * greenMix +
                wAqua * aquaMix + wBlue * blueMix + wPurple * purpleMix + wMagenta * magentaMix
            ) * saturation;

            float baseLuma = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
            float luma = clamp(baseLuma + mixShift * 0.5, 0.0, 1.0);
            return vec4(luma, luma, luma, pixel.a);
        }
        """)
}
