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

## License and contribution agreement

lightLightroom is open source under the GNU Affero General Public License v3.0 only (`AGPL-3.0-only`). See `LICENSE` for the full license text.

The goal is to build one stronger shared photo editor, not a cloud of nearly identical competing apps. True open source licenses must allow people to inspect, modify, and fork the code, so this project does not try to ban forks. Instead, the license and project norms are designed to keep improvements flowing back into the commons:

- If you distribute a modified version, or make a modified network-accessible version available to users, you must provide the corresponding source code under the same AGPL-3.0-only terms.
- Please contribute useful fixes and features upstream with pull requests before maintaining a long-running public fork.
- Do not use the lightLightroom name, logos, icons, screenshots, or product identity for a separate app, fork, store listing, service, or commercial offering without written permission, except where required for attribution or license compliance.
- Clearly rename and distinguish any public modified version that is not accepted into this repository.

By submitting a pull request, patch, issue attachment, design asset, or other contribution to this repository, you agree that your contribution is licensed under `AGPL-3.0-only` and that you have the right to contribute it. You also agree that the maintainers may include, modify, and redistribute your contribution as part of this project under that license.

This README describes the intended project culture and licensing posture, but it is not legal advice. If you need commercial terms, private licensing, or brand-use permission, contact the maintainers before shipping.

