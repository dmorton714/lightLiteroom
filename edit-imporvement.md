# Image Editing Improvement Plan

Goal: improve the editor so RAW and JPEG adjustments feel closer to Adobe Camera Raw / Photoshop RAW editing, especially for white balance, contrast, tonal recovery, and export consistency.

## Progress / Status (updated 2026-09-12)

**The full 10-phase Recommended Build Order in this doc is now complete.** Everything below Phase 9 in "Done" plus Phase 10 (the last remaining phase) has landed. Remaining work is either explicitly deferred earlier in this doc (see "Deferred / out of scope" below) or whatever the user asks for next — there is no more unbuilt work from the original build order.

**Done:**
- Phase 1 — RAW-aware `ImageSource` model (`.data` case, RAW vs JPEG/HEIC handling in one place).
- Phase 2 — White balance split into `Temperature`/`Tint`, mapped to `CITemperatureAndTint` (JPEG) / `CIRAWFilter` (RAW).
- Phase 3 — RAW-native temperature/tint/exposure wired into `CIRAWFilter` decode (not post-render), with the double-apply bug fixed (RAW no longer re-applies temp/tint/exposure after decode).
- Phase 4 — Contrast replaced with a 5-point tone curve. (Note: this phase's original highlights/shadows/blacks/whites fix did not actually close the half-dead-range bug — see the follow-up fix noted below, dated 2026-09-12, which is the one that actually works.)
- Follow-up fix (2026-09-12) — the real fix for the highlights/shadows/blacks/whites half-dead-range bug. `CIHighlightShadowAdjust`'s `highlightAmount`/`shadowAmount` are physically one-directional over 0...1, so no amount of remapping could make the clamped-away half of Highlights/Shadows do anything; and Blacks/Whites drove the tone curve's literal 0/1 endpoints, so pushing either past neutral clipped instantly in one direction. Fixed by replacing the stacked tonal passes with one stronger ACR-style cooperative tone mapper in `Pipeline/AdjustmentPipeline+ToneCurve.swift`: Contrast, Highlights, Shadows, Blacks, and Whites now shape one shared five-point curve with nonlinear slider response, preserved midtones, and small anchor movement only where it helps recovery/detail. The compatibility wrappers in `AdjustmentPipeline+Contrast.swift`, `AdjustmentPipeline+Highlights.swift`, `AdjustmentPipeline+Shadows.swift`, and `AdjustmentPipeline+ToneEndpoints.swift` all route into that shared mapper so preview, export, and old call sites behave the same. Verified with a `#if DEBUG` self-check (`Pipeline/AdjustmentPipeline+DebugToneCheck.swift`, run from `LightLightroomApp.init`) that asserts all four tonal controls produce genuinely visible rendered output at -100 and +100 vs. neutral, plus full iPhone/iPad/Mac Catalyst builds.
- Phase 6 — RAW Detail panel: sharpness, luminance/color noise reduction, detail amount, lens correction toggle (all real `CIRAWFilter` properties, verified against the SDK header).
- Phase 7 (pulled forward, user-authorized) — Black & white toggle + full 8-channel mixer (red/orange/yellow/green/aqua/blue/purple/magenta) via a custom `CIColorKernel` (genuine hue-weighted luminance mixing, not desaturation, triangular interpolation between 8 band centers spaced around the hue wheel). Plus a small `BlackAndWhitePreset` enum (High Contrast, Soft/Classic, Deep Shadows) with a one-tap button row that stamps all 8 mix values and enables black and white mode. Black and white film-profile linkage is explicitly deferred to Phase 9 (film emulation) — not part of this pass.
- Phase 8 — Presence panel: texture, clarity, dehaze, vibrance, saturation, applied post-render (for RAW and non-RAW alike) as a new step after the existing tonal controls in `AdjustmentPipeline`. Texture and clarity use `CIUnsharpMask` at a fine vs. broad radius respectively (fine detail vs. local contrast); dehaze approximates haze removal by reusing the same broad-radius local-contrast boost plus a small extra `CIColorControls` contrast bump (a real approximation, not true haze removal — no depth/atmosphere estimation, per the doc's own accepted hedge); vibrance uses the built-in `CIVibrance` filter; saturation uses `CIColorControls.saturation` remapped from the -100...100 UI range onto its native 0...2 domain. New "Presence" section added to `ContentView`'s adjustments panel, shown unconditionally (not RAW-gated).
- Also done, outside this doc's phases but along the way: full "liquid glass" UI redesign (full-bleed photo, floating draggable adjustments panel, solid bottom toolbar), live luminance histogram, RAW-decode-caching + debounce fix for render latency, and photo persistence across app relaunches (`PhotoStore.swift`).
- Phase 9 — Film emulation: a `FilmProfile` enum (`none`/Clean Digital, `warmPortrait`, `goldenNegative`, `mutedChrome`, `classicMono`, `highContrastMono` — six of the doc's suggested starter set, non-trademarked internal names, `.none` as the neutral default) plus `filmStrength`, `grainAmount`, `grainSize`, `fadeAmount`, `vignetteAmount` on `AdjustmentSettings`. Each profile is a pure-data `Adjustments` bundle (contrast/saturation/temperature/tint bias plus suggested grain/fade/vignette defaults and, for the two mono profiles, forced B&W + channel-mix defaults) — not a separate filter pipeline; `applyFilmProfile` blends it into the existing `applyContrast`/`applyTemperatureAndTint`/`applySaturation` machinery scaled by `filmStrength`. Applied near the end of the pipeline (after presence, before fade/grain/vignette), matching the doc's stated order. Grain uses `CIRandomGenerator` softened with `CIGaussianBlur` (size controls blur radius), desaturated and alpha-scaled by amount, composited over the image — a believable approximation, not a physically accurate simulator. Fade lifts the tone curve's black point. Vignette uses the built-in `CIVignette` filter. Selecting a profile (`FilmProfile.apply(to:)`) sets `filmStrength` to 100, stamps suggested grain/fade/vignette values, and for `classicMono`/`highContrastMono` also sets `isBlackAndWhite = true` plus channel-mix defaults — picking up the B&W film-profile linkage deferred from Phase 7. Users can keep editing every slider afterward; nothing is locked. New "Film" section added to `ContentView`'s adjustments panel: a scrollable profile-picker button row plus five sliders, with `filmStrength` shown only once a non-`.none` profile is selected (grain/fade/vignette stay visible always, as independent finishing controls).
- Phase 10 (final phase) — before/after and reset affordances, all in `ContentView.swift`:
  - **Reset**: a global "Reset All" button in the panel header (next to "Adjust", beside the new RAW/JPEG badge) sets the whole `AdjustmentSettings` back to `.neutral`; the three sectioned panels that already have a header — Presence, Film, RAW Detail — each get their own small "Reset" button that resets only that section's fields (the ungrouped Basic-8 and B&W blocks have no header to hang a per-section button on, so they're covered by "Reset All" only, per planner's call not to add a new header just to host a button).
  - **Before/after toggle**: an eye-icon button in the bottom toolbar (between Export and Gallery) tap-toggles between the live edit and a one-shot render of the same photo with `.neutral` settings (`showOriginalPreview`). Deliberately a separate, narrower render path from the live-preview `scheduleRender` — it only ever sets `renderedPreview`, never `photo.settings`/`histogramBins`/the gallery `thumbnail` — so toggling to "before" can never be mistaken for, or accidentally persisted as, a real edit (`PhotoStore.updateSettings` on backgrounding only ever sees the real `photo.settings`, untouched by this toggle). Automatically snaps back to "after" on any real settings change or photo switch, so the toggle icon and displayed image can't drift out of sync.
  - **Double-tap slider to reset**: `adjustmentSlider` takes a `defaultValue: Double = 0` parameter and double-tapping the slider resets it to that value; every call site relies on the default of 0 except `Grain Size`, which passes `defaultValue: 50` to match its actual neutral default.
  - **RAW vs JPEG indicator**: a small "RAW"/"JPEG" text badge next to "Adjust" in the panel header, driven directly by `photo.isRAW`.
  - Known accessibility gap, not fixed in this pass: `panelHeader`'s outer `VStack` carries `.accessibilityElement(children: .combine)` (pre-existing, for the collapse/expand VoiceOver action), which merges all its children — including the new "Reset All" button and RAW/JPEG badge — into one VoiceOver element. Sighted/touch use of Reset All works correctly (verified via `.highPriorityGesture` beating the header's own drag-to-move gesture), but VoiceOver users currently have no separate way to activate "Reset All" specifically. Fixing this would mean restructuring the header's accessibility tree beyond this phase's scope.

**Session update (2026-09-12, later same day) — new user-authorized work beyond the original 10 phases:**
- **Zoom — DONE, verified, merged.** Pinch/pan on the photo canvas while editing (`Editor/ZoomableImageModifier.swift` for gestures, `Editor/ZoomPanLayout.swift` for pure clamp math), resets to 1x on every photo switch via `.id(currentPhoto?.id)` on `PhotoLayerView`. A swipe-to-switch-photo guard (`ContentView+Layout.swift`) prevents panning a zoomed photo from also triggering a photo switch. Full simulator build verified green.
- **Grain rework — DONE, verified, merged.** User reported grain was "too big," not fine/film-like. Root cause: the old approach Gaussian-blurred `CIRandomGenerator` white noise, which averages away the fine high-frequency texture real grain needs, and used a flat pixel-radius that didn't scale between the downscaled preview and full-res export. New approach (`Pipeline/AdjustmentPipeline+Grain.swift` + `Pipeline/AdjustmentPipeline+GrainNoise.swift`): no Gaussian blur; cell-size-scaled noise instead, two layered passes (fine dense layer + fainter ~3.2x larger clump layer) to mimic real film grain clumping, with cell size scaled by the image's actual resolution so preview and export look the same relative grain size. Verified via scratchpad math check + full simulator build.
- **Presence fix — DONE, verified, merged.** Same investigation found Texture/Clarity (`Pipeline/AdjustmentPipeline+Presence.swift`) had a real dead zone: `CIUnsharpMask` clamps negative `intensity` to a no-op, so the "soften" direction of both sliders did nothing. Fixed by adding `softenLocalContrast(_:radius:amount:)` (blends toward a Gaussian-blurred version — the literal inverse of unsharp-masking) and branching to it when the slider value is negative. Dehaze was checked and found NOT dead (its separate contrast term already responds both directions) — left untouched.
- **Slider audit — DONE.** Every other slider (Temperature, Tint, Exposure, Contrast, Vibrance, Saturation, B&W channel mix, RAW detail, Film/fade/vignette) was checked against the same clamping/dead-zone bug class found in Highlights/Shadows/Blacks/Whites. All confirmed fine — no other instances of this bug.
- **Crop — DONE, verified building.** Rectangular crop + fixed aspect-ratio presets (Original/1:1/4:5/3:2/16:9/Free) are now registered in the Xcode project and building. Crop runs last in `AdjustmentPipeline.apply` (after vignette/grain, since crop changes image extent and grain's resolution-normalization depends on `image.extent`). Crop mode resets zoom to 1x on entry (`ContentView+Crop.swift`) and hides the floating adjustments panel while active. Preview and export already flow through `AdjustmentPipeline.apply`; background thumbnail catch-up was also updated to run the same pipeline on its small thumbnail source so gallery/filmstrip thumbnails match the committed crop. Verified with Debug builds for iPhone 15 simulator, iPad Pro 12.9-inch simulator, and Mac Catalyst.
- **Slider-drag performance — DONE, verified building.** Live slider renders now skip the preview crossfade animation while dragging, reducing stutter without changing panel/dock placement. Verified with Debug builds for iPhone 15 simulator, iPad Pro 12.9-inch simulator, and Mac Catalyst.
- **Polish pass — NOT STARTED.** User said the app "looks like shit, like it's 30 years old." Not yet scoped beyond the planner's original suggestion (audit `Styling/GlassCard.swift`/`GlassDockedPanel.swift`/`DarkDock.swift` for drift against `Styling/Glass.swift`'s tokens, confirm `Glass.spring` is used consistently for all state transitions including the new crop/zoom ones, revisit `PhotoLayerView`'s plain black letterbox). This should happen after crop is finished, so it can sweep crop's new UI chrome too instead of redoing it.
- **Still open, separate issue, not addressed further this session:** Mac Catalyst desktop window layout bug — the bottom dock and floating adjustments panel mis-position (dock can vanish off-screen, panel gets cut off) at certain window sizes. Confirmed live via screenshots earlier this session; root cause not yet nailed down (geometry reported by `GeometryReader` in `Editor/ContentView+Layout.swift` was checked and seemed to update correctly on resize in isolated tests, so the exact trigger condition is still unclear — needs more repro work, ideally with the user driving the window themselves rather than automated resize, since automated window manipulation was found to interfere with the user's own testing).

**Known limitation — accepted for now, fix later:**
For Photos-library assets that pair a RAW file with a JPEG (common with camera-card imports), `PhotosPickerItem.loadTransferable(type: Data.self)` is not guaranteed to fetch the RAW representation specifically over the paired JPEG — Swift's default `Data: Transferable` conformance can't pin a `UTType`. Single-file RAW formats (ProRAW/DNG, most CR3) are unaffected; only RAW+JPEG pairs are at risk. **Fix later**: a custom `Transferable` wrapper that explicitly requests the `.rawImage` representation.

**Deferred / out of scope (not part of the 10-phase build order, or explicitly punted earlier in this doc):**
- The RAW+JPEG Photos-pairing limitation just above.
- Optics panel (chromatic aberration reduction, creative/correction vignette beyond the existing lens-correction toggle) — never started.
- Color panel (HSL/color mixer, split-toning) — never started; the doc always said this could wait until the core pipeline was solid.
- The VoiceOver/"Reset All" accessibility gap noted above.

**Next step when resumed:** The core `edit-imporvement.md` build order (all 10 phases) is complete. Remaining items are the explicitly-deferred ones listed above, or whatever the user requests next.

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

Implementation note (added 2026-09-12, user-requested): the Temperature and Tint
sliders should show a color gradient on their track so the user can see at a
glance what color they're balancing toward/away from — Temperature: blue (cool)
to orange (warm); Tint: green to magenta. SwiftUI's stock `Slider` doesn't
support a gradient track fill, so this needs a small custom slider treatment
(e.g. a `LinearGradient` drawn behind/under the existing track, sized to the
slider's bounds) — reuse the existing `adjustmentSlider` helper's structure,
just for these two controls, not a full custom slider control for every
slider in the panel.

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
- Black and white mode
- Film emulation selections

This can wait until the core RAW pipeline is strong, but the data model should leave room for these settings now.

### Black And White Panel

Add a dedicated black and white mode, similar to Adobe Camera Raw / Photoshop RAW.

UI controls:

- Black and white toggle
- Red mix
- Orange mix
- Yellow mix
- Green mix
- Aqua mix
- Blue mix
- Purple mix
- Magenta mix

Implementation notes:

- This should not be a simple desaturation filter.
- Use channel mixing so users can control how each color maps into luminance.
- Skin tones should be strongly affected by red/orange/yellow mix controls.
- Skies should be strongly affected by aqua/blue controls.
- Preserve the existing tonal controls after the black and white conversion.

Suggested pipeline position:

1. RAW decode / base color render
2. exposure and white balance
3. black and white color mix, if enabled
4. contrast / tone curve
5. highlights, shadows, blacks, whites
6. grain, vignette, and film finishing

### Film Emulation Panel

Add selectable film looks in the UI.

Initial UI:

- Film profile picker
- Film strength slider
- Grain amount
- Grain size
- Fade amount
- Vignette amount

Possible starter profiles:

- Clean Digital
- Kodak Portra-style color
- Kodak Gold-style warm color
- Fujifilm-style color
- Classic Chrome-style muted color
- Tri-X-style black and white
- Ilford HP5-style black and white
- High Contrast Mono

Implementation notes:

- Avoid naming profiles as exact trademarked film stocks in the final UI unless we are comfortable with that. Internally we can use descriptive approximations like `warmPortrait`, `goldenNegative`, `mutedChrome`, and `classicMono`.
- Each film profile should be a preset bundle, not a baked image filter.
- Profiles can adjust tone curve, color matrix/HSL, saturation, color grading, grain, and vignette.
- Film strength should blend the profile adjustments with the user's base edit.
- Users should still be able to edit after selecting a profile.
- Black and white film profiles should automatically enable black and white mode and set channel mix defaults.

Good first implementation:

- Add an enum for film profile.
- Add `filmStrength`, `grainAmount`, `grainSize`, `fadeAmount`, and `vignetteAmount` to `AdjustmentSettings`.
- Apply film look near the end of the pipeline, after core tonal correction but before final grain/vignette.
- Build profile definitions as data so new looks can be added without rewriting pipeline logic.

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

### Phase 7: Add black and white editing

Add a real black and white mode with color-channel mix controls.

This should include:

- black and white toggle
- channel mix sliders
- black and white presets
- support for black and white film profiles

The goal is to make black and white conversion feel intentional and photographic, not like saturation set to zero.

### Phase 8: Add film emulation

Add film profile selections to the UI.

Start with a small, high-quality set:

- neutral color
- warm portrait color
- golden negative color
- muted chrome color
- classic black and white
- high contrast black and white

Each profile should define:

- tone curve
- color response
- saturation/vibrance behavior
- optional split tone or color grading
- grain defaults
- vignette/fade defaults

Film profiles should work as editable starting points, not destructive one-click filters.

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
8. Add black and white mode with color mix controls.
9. Add film emulation profiles and finishing controls.
10. Add before/after and reset affordances.
