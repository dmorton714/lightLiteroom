# macOS Export App Plan

Goal: make lightLightroom exportable as a Mac app while keeping the current iPhone/iPad app stable.

## Current App Shape

The app has been split into smaller folders:

- `App`: SwiftUI app entry point.
- `Editor`: root editor state, rendering/import/export/persistence extensions, photo layout.
- `Dock`: bottom toolbar, import/export buttons, filmstrip controls.
- `Gallery`: persisted gallery view.
- `Models`: settings, film profiles, photo records.
- `Panel`: adjustment panel and slider sections.
- `Pipeline`: Core Image adjustment pipeline and kernels.
- `Services`: image source handling, preview rendering, export, persistence, RAW cache.
- `Styling`: glass/dock/material styling helpers.

This structure is good for a Mac port because the reusable image model and pipeline are already separated from most UI.

## Recommended Path

Start with Mac Catalyst.

Why:

- The app is already SwiftUI-based.
- The image pipeline is built on Core Image, which is available on macOS.
- Catalyst should reuse more of the existing iPad app than a native AppKit target.
- It gives us a fast proof that rendering, import, adjustment, persistence, and export can work on Mac before investing in desktop-native UI.

Native macOS can come later if the app needs a true desktop workflow: menu commands, multi-window editing, Finder drag/drop, AppKit file panels, and Mac-specific keyboard behavior.

## Compatibility Notes From Re-scan

Ready:

- `Pipeline` is Core Image based and should be portable.
- `Models` are platform-light, except thumbnails use `UIImage` through `EditedPhoto`.
- `Services` are mostly reusable; `PreviewRenderer`, thumbnails, and export use `UIImage`, which is fine for Catalyst.
- The reorganized project builds successfully for iPhone simulator before Catalyst changes.

Needs attention:

- `PhotosPicker` lives in `Dock/ToolbarButtonsRow.swift` and import handling lives in `Editor/ContentView+Import.swift`.
- `ExportService` writes to `PHPhotoLibrary`; Catalyst may build, but desktop users will probably expect file export later.
- The UI is still phone/tablet-first and may feel constrained in a resizable Mac window.

## Phase 1: Catalyst Build Target

Implementation:

- Enable Mac Catalyst support on the existing iOS target.
- Keep iPhone/iPad support untouched.
- Build for iPhone simulator after the project change.
- Try a Mac destination build.

Done in this branch:

- Added `SUPPORTS_MACCATALYST = YES`.
- Added a Mac-specific bundle ID with `PRODUCT_BUNDLE_IDENTIFIER[sdk=macosx*] = com.dannymorton.lightLightroom.mac`.
- Verified that Xcode exposes `platform=macOS,variant=Mac Catalyst`.
- Verified Catalyst compilation with `CODE_SIGNING_ALLOWED=NO`.

Signing note:

- A normal signed Catalyst build still needs an Apple development team selected in Xcode. The compile path is healthy; signing is the remaining local configuration step for running/exporting a signed Mac app.

## Phase 2: Desktop Import/Export Polish

Potential implementation tasks:

- Add Mac-friendly import through file picker and/or drag/drop.
- Keep Photos import for platforms where it works well.
- Add Mac-friendly export location selection.
- Preserve iOS Photos export behavior.

Likely approach:

- Share `ImageSource`, `AdjustmentSettings`, `AdjustmentPipeline`, and export rendering.
- Isolate platform-specific picker/export UI behind small conditional branches.

## Phase 3: Desktop UX

Potential implementation tasks:

- Keyboard shortcuts for import, export, before/after, reset, gallery.
- More comfortable resizable window layout.
- Toolbar/menu commands.
- Optional multi-window support later.

This should wait until Catalyst build/import/export are proven.

## Risks

- `PhotosPicker` behavior may differ on Mac Catalyst.
- `UIImage` and `UIKit` are available in Catalyst but may become limiting for a native macOS target.
- Photos-library export permissions may need different handling on macOS.
- Existing phone/tablet layout may feel awkward in a resizable desktop window.
- Xcode project edits can conflict with active feature work, so keep Mac changes narrow.

## Next Steps

1. Verify iPhone simulator build.
2. Verify Mac Catalyst destination/build availability.
3. If Catalyst builds, open/run it and test import/edit/export manually.
4. If Catalyst does not build, fix only the reported build blockers.
5. Add desktop import/export polish after the proof build works.
