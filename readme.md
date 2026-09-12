# lightLightroom

A Swift/SwiftUI RAW + JPEG photo editor, built to feel closer to Adobe Camera Raw than a typical phone filter app. Runs on iPhone, iPad, and Mac (via Catalyst).

## Running the app

```
./run
```

This builds and launches all three targets — iPhone Simulator, iPad Simulator, and Mac (Catalyst) — in one shot. It also re-syncs the Xcode project's file list from whatever `.swift` files exist on disk first (`scripts/sync_project.py`), so a newly added file never causes a stale "cannot find X in scope" build failure.

Requirements: Xcode + at least one iPhone and one iPad simulator installed (Xcode > Settings > Platforms). No signing/developer team needed — Mac Catalyst builds ad-hoc.

If a single target fails, `./run` prints which one and why, and still attempts the rest.

## What it does

- Imports RAW and JPEG/HEIC photos from the Photos library.
- Adjustments: white balance (temperature/tint), exposure, contrast, highlight recovery, shadow recovery, blacks, whites, presence (texture/clarity/dehaze/vibrance/saturation), black & white channel mixer, film emulation profiles, grain/fade/vignette.
- Zoom/pan on the photo while editing; crop with fixed aspect-ratio presets.
- Gallery of imported photos with a live-updating filmstrip; edits and imports persist across relaunches.
- Exports the edited image back to the device at full resolution, using the same render pipeline as the live preview.
- Before/after toggle, per-slider double-tap-to-reset, and a global reset.

## Project layout

- `lightLightroom/lightLightroom/` — app source, organized by feature (`Editor/`, `Panel/`, `Dock/`, `Pipeline/`, `Models/`, `Services/`, `Styling/`).
- `lightLightroom/scripts/sync_project.py` — regenerates `project.pbxproj`'s file references from disk. Run it (or just use `./run`, which calls it automatically) any time you add, move, or delete a `.swift` file by hand instead of through Xcode.
- `edit-imporvement.md` — the working build log/tracker for the editing pipeline: what's done, what's in progress, known limitations. Check it before starting new pipeline work.

## Original goals (project brief)

- Read in RAW and JPEG photos.
- Basic RAW-aware adjustments: white balance, exposure, contrast, highlight recovery, shadow recovery, blacks, whites.
- Export edited images back to the device.
- A gallery to see imported/edited photos.
- An app icon/logo.
- Photos persist across relaunches, not just the current session.
- Works well on both iPhone and iPad screen sizes, not just iPad.
