# macOS Export App Plan

Goal: make lightLightroom exportable as a Mac app while keeping the current iPhone/iPad app stable.

Current constraint: do not modify the existing Swift source files or Xcode project while other feature work is active. This branch is for planning and agent setup only.

## Recommended Path

Start with Mac Catalyst.

Why:

- The app is already SwiftUI-based.
- The image pipeline is built on Core Image, which is available on macOS.
- Catalyst should reuse more of the existing iPad app than a native AppKit target.
- It gives us a fast proof that rendering, import, adjustment, persistence, and export can work on Mac before investing in desktop-native UI.

Native macOS can come later if the app needs a true desktop workflow: menu commands, multi-window editing, Finder drag/drop, AppKit file panels, and Mac-specific keyboard behavior.

## Agents Added

- `.claude/agents/macos-port-planner.md`
- `.claude/agents/macos-compat-auditor.md`
- `.claude/agents/macos-build-engineer.md`

Use order:

1. `macos-port-planner`
2. `macos-compat-auditor`
3. `macos-build-engineer`, only after code/project edits are explicitly allowed

## Phase 1: Compatibility Audit

Read-only tasks:

- Inspect Xcode supported platforms and device families.
- Identify iOS-only APIs.
- Check `PhotosUI` import behavior under Mac Catalyst.
- Check `UIKit` usage.
- Check export permissions and Photos-library assumptions.
- Check file persistence paths under Mac sandboxing.
- Check SwiftUI layout assumptions that depend on phone/tablet orientation.

Expected output:

- What works as-is.
- What needs Catalyst guards.
- What needs a user decision.
- Smallest implementation path.

## Phase 2: Catalyst Build Target

Potential implementation tasks once edits are allowed:

- Enable Mac Catalyst support for the existing iOS target.
- Add any required signing/entitlement/privacy settings.
- Verify the project still builds for iPhone/iPad simulator.
- Build for a Mac Catalyst destination.

Do not change image processing logic in this phase.

## Phase 3: Desktop Import/Export Polish

Potential implementation tasks:

- Add Mac-friendly import through file picker and/or drag/drop.
- Keep Photos import for platforms where it works well.
- Add Mac-friendly export location selection.
- Preserve iOS Photos export behavior.

Likely approach:

- Share `ImageSource`, `AdjustmentSettings`, `AdjustmentPipeline`, and export rendering.
- Isolate platform-specific picker/export UI behind small conditional branches.

## Phase 4: Desktop UX

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
- Xcode project edits can conflict with other active feature work, so they should happen only when the current app changes are stable.

## First Implementation Step Later

When code/project edits are allowed:

1. Run the compatibility audit.
2. Enable Catalyst on the existing target.
3. Build for Mac.
4. Fix only the build blockers.
5. Rebuild for iPhone simulator to confirm no regression.

Until then, keep this branch planning-only.
