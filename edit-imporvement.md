# Image Editing Improvement Plan

Goal: improve the editor so RAW and JPEG adjustments feel closer to Adobe Camera Raw / Photoshop RAW editing, especially for white balance, contrast, tonal recovery, and export consistency.

## Current State

The app already has a clean basic editing flow:

- Import images through `PhotosPicker`.
- Store a full-resolution source image and a downsampled preview image.
- Apply seven basic adjustments through `AdjustmentPipeline`.
- Render fast previews while sliders move.
- Reapply the same settings to the full-resolution image on export.

The main limitation is that RAW files are currently treated much like regular bitmap images after import. White balance and contrast are applied after generic image decoding, instead of using RAW-aware controls before demosaicing/rendering.

## Main Problems To Fix

### 1. RAW files need a true RAW decode path

Current import uses `CIImage(data:)`, which is simple but does not expose the full RAW editing controls that Core Image provides.

For RAW files, we should use `CIRAWFilter` so the app can adjust:

- RAW neutral temperature
- RAW neutral tint
- RAW exposure
- baseline exposure
- RAW local tone mapping
- RAW contrast/detail controls when supported
- lens correction and noise reduction when supported

JPEG/HEIC images can continue using the regular `CIImage(data:)` path.

### 2. White balance should be temperature + tint

The app currently has one `White Balance` slider. Photoshop RAW-style editing should split this into:

- `Temperature`
- `Tint`

For RAW images:

- `Temperature` should map to `CIRAWFilter.neutralTemperature`.
- `Tint` should map to `CIRAWFilter.neutralTint`.

For JPEG/HEIC images:

- Use `CITemperatureAndTint`.
- Map the same UI controls into a post-render correction.

This will make RAW white balance feel much more natural and give users the green/magenta correction they expect.

### 3. Contrast should use a better tonal model

The current contrast adjustment uses `CIColorControls.contrast`, which is blunt. It changes the whole image at once and can make highlights, shadows, and skin tones feel harsh.

A better approach is a custom tone curve:

- Keep the midpoint stable.
- Use a gentle S-curve for positive contrast.
- Use a flatter curve for negative contrast.
- Avoid pushing pure black and pure white too hard.
- Let `Blacks` and `Whites` control the endpoints separately.

This is closer to how RAW editors separate global contrast from black/white point control.

### 4. Preview and export should share the same render path

Preview and export should use the same pipeline so the image does not change unexpectedly when exported.

For JPEG/HEIC:

- Decode once.
- Downsample for preview.
- Apply the same adjustment pipeline to preview and full-res export.

For RAW:

- Build a `CIRAWFilter` for preview with a lower `scaleFactor`.
- Build a `CIRAWFilter` for export with full `scaleFactor`.
- Apply the same RAW settings and post-render settings in both paths.

## Proposed Feature Set

This should move the app closer to Photoshop RAW editor basics.

### Basic Panel

- Temperature
- Tint
- Exposure
- Contrast
- Highlights
- Shadows
- Whites
- Blacks

### Presence / Detail Panel

Add after the basic controls feel good:

- Texture
- Clarity
- Dehaze
- Vibrance
- Saturation

Implementation notes:

- `Clarity` can start as local contrast.
- `Texture` can be a finer detail enhancement.
- `Dehaze` may need a custom Core Image filter or approximated curve/local contrast approach.
- `Vibrance` should protect already-saturated colors and skin tones better than plain saturation.

### RAW Detail Panel

For RAW files only where supported:

- Sharpening
- Luminance noise reduction
- Color noise reduction
- Detail amount
- Lens correction toggle

These map well to `CIRAWFilter` capabilities.

### Color Panel

Later, to get closer to Adobe Camera Raw:

- HSL / Color Mixer
- Color grading wheels or simpler shadows/midtones/highlights tint controls
- Black and white mix

This can wait until the core RAW pipeline is strong.

### Optics Panel

Later:

- Enable lens correction by default when supported.
- Add chromatic aberration reduction if practical.
- Add vignette correction or creative vignette.

## Implementation Plan

### Phase 1: Add RAW-aware image source

Create a small model that keeps:

- original image `Data`
- optional filename or type hint
- whether the image is RAW
- preview scale information

Replace `EditedPhoto.sourceImage` / `previewSourceImage` with a source that can render either:

- preview image
- full-resolution export image

This gives us one place to handle RAW vs JPEG behavior.

### Phase 2: Split white balance controls

Update `AdjustmentSettings`:

- replace `whiteBalance` with `temperature`
- add `tint`

Suggested ranges:

- UI temperature: `-100...100`
- UI tint: `-100...100`

Internally:

- RAW temperature maps around the camera/default neutral temperature.
- RAW tint maps around the camera/default neutral tint.
- JPEG temperature/tint maps to `CITemperatureAndTint`.

### Phase 3: Move RAW adjustments into RAW decode

For RAW images, apply these before getting `outputImage`:

- temperature
- tint
- exposure
- local tone map amount if useful
- contrast/detail if supported
- lens correction if supported

Then pass the rendered RAW image into the post-render pipeline for:

- tone curve contrast
- highlights/shadows
- blacks/whites
- color/presence adjustments

### Phase 4: Replace global contrast

Replace `CIColorControls.contrast` with a custom tone curve.

Start with a conservative S-curve:

- `point0`: keep close to `(0, 0)`
- `point1`: move down slightly for positive contrast
- `point2`: keep `(0.5, 0.5)`
- `point3`: move up slightly for positive contrast
- `point4`: keep close to `(1, 1)`

Negative contrast should do the opposite.

The curve should be tuned against:

- `P4260041.ORF`
- `P9050131.ORF`
- `4M4A1115.CR3`
- `Wilemon_Katherine_689--0002.jpg`

### Phase 5: Add better tonal recovery

Improve highlights and shadows so they feel less like a generic filter.

Options:

- Keep `CIHighlightShadowAdjust`, but tune the slider mapping.
- Add tone curve shaping around highlights and shadows.
- For RAW files, test `CIRAWFilter.localToneMapAmount` and `extendedDynamicRangeAmount`.

Goal:

- highlights should recover sky/detail without making the image gray
- shadows should lift detail without flattening the whole photo

### Phase 6: Add UI polish for editing

Add controls that feel more like a RAW editor:

- grouped panels
- reset button per slider or per panel
- numeric values
- before/after toggle
- double-tap slider to reset
- indicator when editing a RAW file vs JPEG

## Success Criteria

White balance:

- RAW temperature changes should look natural, not like a color overlay.
- Tint should clearly correct green/magenta casts.
- JPEG white balance should still work reasonably.

Contrast:

- Increasing contrast should add depth without instantly crushing shadows or blowing highlights.
- Decreasing contrast should soften the image without making it muddy.
- Blacks and whites should remain useful independent controls.

Preview/export:

- Preview and exported image should look materially the same.
- RAW preview should stay responsive.
- Full-res export should preserve as much quality as practical.

User experience:

- The editor should feel familiar to someone who has used Photoshop RAW / Adobe Camera Raw.
- The first visible editing controls should remain simple and useful.
- More advanced controls can be grouped below the basic panel.

## Recommended Build Order

1. Add RAW source/render abstraction.
2. Split white balance into temperature and tint.
3. Use `CIRAWFilter` for RAW preview and export.
4. Replace contrast with a tone curve.
5. Retune highlights, shadows, blacks, and whites.
6. Add RAW detail controls.
7. Add presence controls: texture, clarity, dehaze, vibrance, saturation.
8. Add before/after and reset affordances.

