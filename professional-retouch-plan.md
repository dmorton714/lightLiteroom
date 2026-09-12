# Professional Subject Selection And Retouch Plan

Goal: add Lightroom/Photoshop-style local editing that can detect a person, edit the subject independently, invert the same mask to edit the background, and support professional portrait retouching such as skin smoothing, blemish cleanup, and flyaway hair removal.

This plan intentionally scopes beyond a simple blur/smooth filter. Skin smoothing can start with Core Image, but professional flyaway cleanup requires a healing/inpainting workflow, either with a local Core ML model, a manual healing brush, or both.

## Product Shape

### User-facing tools

- `Global`: current whole-image editing behavior.
- `Subject`: automatically detect the person and apply adjustments only to them.
- `Background`: use the same subject mask inverted, so the background can be edited independently.
- `Retouch`: portrait cleanup tools that operate on a selected person/face region.
- `Heal`: brush-based cleanup for flyaway hair, blemishes, lint, dust, and small distractions.

### Expected controls

Subject/background local edits:

- Exposure
- Contrast
- Highlights
- Shadows
- Whites
- Blacks
- Temperature
- Tint
- Texture
- Clarity
- Saturation
- Optional: blur/background soften later

Retouch controls:

- Skin Smooth
- Texture Restore
- Blemish Softening
- Eye/Lip/Detail Protection
- Flyaway Hair Cleanup
- Brush Size
- Brush Feather
- Brush Opacity
- Before/After toggle

## Architecture Overview

The current app has one global `AdjustmentSettings` per photo. We should add local adjustment layers and mask assets.

Proposed model:

```swift
struct EditedPhoto {
    var imageSource: ImageSource
    var globalSettings: AdjustmentSettings
    var localAdjustments: [LocalAdjustment]
}

struct LocalAdjustment: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var mask: MaskReference
    var settings: LocalAdjustmentSettings
    var blendMode: LocalBlendMode
    var opacity: Double
}

struct LocalAdjustmentSettings: Codable, Equatable {
    var exposure: Double = 0
    var contrast: Double = 0
    var highlights: Double = 0
    var shadows: Double = 0
    var blacks: Double = 0
    var whites: Double = 0
    var temperature: Double = 0
    var tint: Double = 0
    var texture: Double = 0
    var clarity: Double = 0
    var saturation: Double = 0
}

enum MaskReference: Codable, Equatable {
    case person(PersonMaskID, inverted: Bool)
    case face(FaceMaskID)
    case brush(BrushMaskID)
    case composite([MaskReference])
}
```

Keep local settings narrower than `AdjustmentSettings`. RAW decode controls, film profiles, grain, vignette, and export-level effects should stay global unless there is a clear reason to localize them.

## Phase 1: Subject And Background Selection

Use Apple Vision person segmentation as the first mask source.

Implementation:

- Add a `MaskStore` that can generate and cache person masks by photo ID and render size.
- Use `VNGeneratePersonSegmentationRequest` for person masks.
- Generate fast preview masks for live editing.
- Generate full-resolution masks for export.
- Feather and refine masks before blending.
- Store cached masks separately from the original image data.

Preview behavior:

- When the user taps `Subject`, show a short detecting state.
- Once detection finishes, tint the subject overlay briefly.
- When the user taps `Background`, reuse the same mask with `inverted = true`.
- If no person is detected, show a small non-blocking message and keep the user in global mode.

Pipeline behavior:

1. Decode RAW/JPEG source.
2. Apply global settings.
3. For each local adjustment:
   - Apply local adjustment settings to the globally edited image.
   - Blend the local result back with `CIBlendWithMask`.
4. Apply final global finishing effects such as grain/vignette/export conversion.

Mask cleanup:

- `CIGaussianBlur` for feathering.
- `CIMorphologyMaximum` to expand masks.
- `CIMorphologyMinimum` to contract masks.
- Optional edge-aware refinement later if hair edges look too crunchy.

## Phase 2: Face And Skin Region Detection

Person segmentation is not enough for professional retouching. We need face-aware and skin-aware masks so smoothing does not affect eyes, eyebrows, lips, teeth, jewelry, clothes, or hair.

Implementation:

- Use `VNDetectFaceRectanglesRequest` to find faces.
- Use `VNDetectFaceLandmarksRequest` to identify eyes, brows, lips, nose, and face outline.
- Build a soft face mask from the landmarks.
- Subtract protected regions:
  - eyes
  - eyebrows
  - lips
  - nostrils
  - hairline where possible
- Optionally add a skin-color confidence mask inside the face/person mask.

Result:

- `personMask`: whole subject.
- `backgroundMask`: inverted person.
- `faceMask`: broad facial area.
- `skinMask`: face/skin pixels only.
- `protectedDetailMask`: eyes, brows, lips, hard edges.

## Phase 3: Professional Skin Smoothing

Avoid plain blur. It looks cheap quickly.

Use frequency separation:

1. Create a low-frequency layer for broad tone/color.
2. Create a high-frequency detail layer from the original.
3. Smooth only the low-frequency skin tone.
4. Reintroduce high-frequency texture at a controlled strength.
5. Apply only through the refined skin mask.

Controls:

- `Skin Smooth`: how much low-frequency smoothing to apply.
- `Texture Restore`: how much pore/detail information to bring back.
- `Blemish Softening`: localized reduction of strong red/dark spots.
- `Detail Protection`: strengthens eye/lip/brow/edge exclusion.

Core Image can handle the first version:

- `CIGaussianBlur`
- `CIMaskedVariableBlur` if useful
- custom `CIColorKernel` / `CIKernel` for frequency separation blend math
- `CIBlendWithMask`

Quality target:

- Skin should look cleaner but still have pores and natural shape.
- Eyes, lips, lashes, brows, nostrils, jewelry, and clothing must remain crisp.
- The effect should be subtle at default values.

## Phase 4: Healing Brush Foundation

Professional flyaway cleanup needs a real healing workflow. Build this before attempting automatic hair cleanup.

User experience:

- User enters `Heal`.
- User paints over a flyaway hair, blemish, or small distraction.
- App either chooses a source region automatically or lets the user drag a source point.
- The healed result is stored as an editable retouch layer.

Data model:

```swift
struct HealStroke: Identifiable, Codable, Equatable {
    var id: UUID
    var points: [CGPoint]
    var radius: Double
    var feather: Double
    var opacity: Double
    var mode: HealMode
    var sourcePoint: CGPoint?
}

enum HealMode: Codable, Equatable {
    case heal
    case clone
    case contentAware
}
```

Implementation levels:

- `Clone`: copy pixels from source to target with feathered blending.
- `Heal`: copy texture/detail from source while matching target luminance/color.
- `ContentAware`: use an inpainting model to synthesize missing background/hair texture.

Start with clone/heal because they are deterministic and useful. Add content-aware once the stroke system exists.

## Phase 5: Content-aware Inpainting For Flyaways

This is the key difference between basic and professional.

Options:

### Option A: Local Core ML inpainting model

Use a local image inpainting model converted to Core ML.

Pros:

- Works offline.
- Private.
- Can feel integrated and fast after optimization.

Cons:

- Model selection/conversion is real work.
- App size increases.
- Performance on simulator may be poor.
- Needs tiling for large photos.
- Quality varies dramatically by model.

Technical requirements:

- Input image crop.
- Binary mask crop for the pixels to remove.
- Context padding around the target area.
- Model output composited back into the full image.
- Tiled inference for large edits.
- Color matching to the surrounding image.

### Option B: Manual heal/clone first, inpainting later

Pros:

- Faster to ship.
- Reliable for professional users who understand retouching.
- Works for flyaways against simple backgrounds.
- No model dependency.

Cons:

- Less automatic.
- Harder for casual users.
- Complex backgrounds still need careful manual work.

### Option C: Hybrid

Recommended.

- Ship manual heal/clone first.
- Add automatic source picking.
- Add local inpainting as an advanced mode.
- Keep manual override for cases where AI guessing fails.

## Phase 6: Automatic Flyaway Hair Cleanup

Automatic flyaway cleanup should be built on top of the healing/inpainting foundation, not as a standalone blur.

Detection approach:

- Start from the person/face/hair boundary.
- Find thin, high-contrast strands extending outside the main hair mass.
- Favor candidates near the head silhouette.
- Exclude eyelashes, eyebrows, clothing edges, and jewelry.
- Generate a proposed removal mask.

User experience:

- `Flyaways` slider proposes cleanup strength.
- `Show Mask` lets the user inspect affected hair strands.
- User can erase/add to the mask with a brush.
- App runs healing/inpainting only on the final approved mask.

Implementation steps:

1. Detect head/person mask edge.
2. Extract thin line candidates outside the subject boundary.
3. Rank candidates by length, contrast, orientation, and proximity to head.
4. Convert candidates to a cleanup mask.
5. Let user refine the mask.
6. Inpaint/heal the masked pixels.
7. Composite result as a non-destructive retouch layer.

This is difficult. It should be treated as a later professional pass, not the first retouch milestone.

## Phase 7: Persistence And Export

All local edits and retouch strokes should survive app relaunch and export consistently.

Persist:

- local adjustment layers
- mask references
- mask cache metadata
- heal strokes
- generated retouch layer outputs if recomputing is too expensive

Export:

- Re-run masks at export resolution where practical.
- Re-apply local adjustments in the same order as preview.
- Re-apply heal/inpainting layers at full resolution.
- If a retouch layer was generated at preview resolution only, mark it as needing regeneration before export.

Non-destructive editing rule:

- Never overwrite the original imported image.
- Retouch outputs are layers or derived assets.
- User can disable/delete each local edit or heal stroke.

## Phase 8: UI Integration

Add a mode switch in the adjustment panel:

- `Global`
- `Subject`
- `Background`
- `Retouch`
- `Heal`

Recommended UI behavior:

- Local modes show a mask overlay button.
- Subject/background modes reuse the existing slider styling.
- Retouch mode shows portrait-specific controls.
- Heal mode replaces sliders with brush controls.
- The bottom toolbar gets a compare button for retouch before/after.

Avoid hiding complexity too much. Professional users need inspectable masks, brush refinement, and layer control.

## Technical Risks

- Vision person segmentation may struggle with multiple people, pets, complex clothing, or unusual poses.
- Hair edges are the hardest part of subject masks.
- Skin smoothing can look artificial unless detail protection is strong.
- Core ML inpainting quality depends heavily on model choice.
- Full-resolution RAW export with masks and inpainting may be slow.
- Simulator performance will not represent real iPhone/iPad performance.
- A professional retouch feature needs careful undo/redo and layer editing.

## Recommended Build Order

1. Add local adjustment data model with `Global`, `Subject`, and `Background` modes.
2. Add Vision person segmentation and mask caching.
3. Blend local subject/background adjustments through Core Image masks.
4. Add mask overlay and simple mask refinement controls.
5. Add face/landmark detection and skin/protected-detail masks.
6. Add frequency-separation skin smoothing.
7. Add heal/clone brush strokes as editable non-destructive layers.
8. Add automatic source selection for healing.
9. Evaluate and integrate a local Core ML inpainting model.
10. Add automatic flyaway candidate detection and mask refinement.
11. Add full-resolution export regeneration for all local/retouch layers.
12. Add undo/redo and per-layer enable/delete controls.

## Difficulty Estimate

Subject/background editing:

- Medium.
- Very achievable with Vision and Core Image.

Professional skin smoothing:

- Medium to medium-hard.
- Achievable with face landmarks, skin masks, and frequency separation.

Manual heal/clone:

- Medium-hard.
- Mostly UI, brush rendering, coordinate mapping, and non-destructive persistence.

Content-aware flyaway cleanup:

- Hard.
- Requires inpainting, high-quality masks, model evaluation, tiling, and user refinement.

Automatic flyaway detection:

- Hard.
- Best treated as an assistive mask generator, not a fully automatic one-click promise.

## Practical Recommendation

Build this as two professional layers:

1. Masked local editing and skin retouching first. This gives a strong, useful feature quickly.
2. Healing/inpainting second. This is the real foundation for professional flyaway cleanup.

Do not ship flyaway cleanup as a blur or edge-smoothing trick. It will look impressive on a few simple images and fail badly on real portraits. The professional path is editable masks plus healing/inpainting, with manual refinement always available.
