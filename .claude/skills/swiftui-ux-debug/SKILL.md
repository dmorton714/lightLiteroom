---
name: swiftui-ux-debug
description: Use whenever fixing a SwiftUI layout/UX bug in lightLightroom — panels, docks, sliders, safe areas, sizing, anything visual that's "off" on some device/window size. Also use before claiming any SwiftUI layout fix is done. Covers iOS, iPadOS, and Mac Catalyst.
---

# SwiftUI UX Debugging — Senior Dev Discipline

You are debugging this as a senior SwiftUI engineer with ~10 years of
platform experience, not as someone pattern-matching a plausible-looking
fix. That means: you find the actual mechanism, you verify it against
documented framework behavior, and you prove the fix with evidence before
you ever tell the user to test. "This should fix it" is not a deliverable.

## The failure mode this skill exists to prevent

The recurring mistake on this project has been: spot one plausible cause,
change it, rebuild, tell the user to test, and be wrong — repeatedly,
burning the user's trust and time. Symptoms that this is happening again:

- You're about to say "should be fixed" / "please test" without having
  reproduced the *original* repro steps yourself, post-fix.
- You changed something because it "seemed related" without tracing the
  actual value that's wrong.
- You're stacking a second speculative change on top of a first one you
  never confirmed.
- You're reasoning about frame math in your head across three chained
  modifiers instead of just measuring it.

If you notice any of these, stop and go back to Step 1.

## Step 1 — Nail the exact repro

Get (or write down for yourself) the *precise* trigger, not a vague
category:

- What screen/device/window size.
- What sequence of actions (e.g. "collapse the filmstrip, not just open
  it" — the trigger condition itself is a real clue, don't discard it).
- What's expected vs. what actually happens.

If the user gives a new/refined repro after a "fix," that refinement is
signal that the previous fix addressed a symptom or a sibling bug, not the
root cause. Treat it as such — don't just patch the new symptom on top.

## Step 2 — Get ground truth, don't infer it

Screenshots alone are not ground truth for layout bugs — pixel-measuring a
screenshot to back-derive frame math is slow and error-prone (this project
has burned real time on exactly that). Instead, instrument the running app
directly and read real numbers:

- Add a temporary on-screen debug readout (`Text` overlay) printing the
  actual runtime values in play: `geometry.size`, `geometry.safeAreaInsets`,
  computed layout values (panel width/height, dock height,
  `isPanelCollapsed`, etc.). Every value you're reasoning about should be
  on screen, not assumed.
- Re-derive nothing you can directly print. If you're about to write "X
  should be Y because Z," stop and print X instead.
- When you change ONE thing, re-test the exact same repro from Step 1
  before touching anything else. One variable at a time.
- Only remove debug instrumentation once the bug is confirmed fixed via
  that same instrumentation.

## Step 3 — Check the actual documented behavior, don't assume it

SwiftUI layout semantics (safe areas, `overlay(alignment:)`, `ignoresSafeArea()`,
`GeometryReader`, `ViewThatFits`, frame proposal/response) are precisely
specified but frequently misremembered, and they differ across iOS/iPadOS/
Mac Catalyst. Before asserting how something behaves:

- If you're not >90% certain of current, platform-specific behavior, use
  `WebFetch`/`WebSearch` against Apple's developer documentation or current
  WWDC session notes rather than relying on memory. Being wrong about
  framework semantics is how the last three "fixes" failed.
- Mac Catalyst specifically has known scaling/safe-area quirks (UIKit point
  space vs. the real AppKit window can diverge — "Scaled to Match iPad" vs.
  "Optimize Interface for Mac"). If a bug is Catalyst-only, check whether
  it's platform-idiom-specific before assuming it's a SwiftUI logic bug at
  all.
- Prefer framework-native adaptive primitives over hand-derived math:
  `safeAreaInset(edge:content:)` instead of manual safe-area padding,
  `containerRelativeFrame`/`ViewThatFits` instead of manual breakpoints,
  `.frame(minWidth:minHeight:)` / `windowResizability` for window bounds.
  Hand-rolled percentage/magic-number math (this codebase has some in
  `PanelLayout`) is exactly where these bugs keep hiding — treat any
  hardcoded fraction or fixed point value you encounter as a suspect, not
  as settled.

## Step 4 — Fix the mechanism, not the symptom

Once you can point to the specific line and the specific wrong value (not
"probably this modifier"), make the smallest change that corrects the
mechanism. Do not:

- Reorder modifiers/overlays as a guess to see if it helps without knowing
  why it would.
- Add a second unrelated change "just in case" alongside the real fix —
  it makes the next regression impossible to attribute.
- Hardcode a position/size to paper over a dynamic-sizing bug. Every fix
  must hold across the full size matrix in Step 5, not just the one window
  size you happened to be testing.

## Step 5 — Verify across the real size matrix before saying anything is fixed

A fix that works at one window size and is untested elsewhere is not
verified. Before reporting a layout fix as done, mentally (and where
feasible, actually) check it against:

- iPhone: smallest current model (SE-class compact width) and a Pro Max,
  both orientations.
- iPad: split view / narrow multitasking width, not just full-screen.
- Mac Catalyst: the app's enforced minimum window size, a small-but-above-
  minimum size, and a large/maximized size — this project's dock+panel bug
  has specifically reproduced only at certain window heights, so window
  size is a first-class variable here, not an edge case.
- Any state toggle that changes reserved chrome height (filmstrip open vs.
  collapsed vs. hidden; panel expanded vs. collapsed) — this project's bugs
  have repeatedly been state-transition-dependent, not static-layout bugs.

Re-run the *original* repro from Step 1 in this pass, with the debug
instrumentation from Step 2 still in place, and read the actual numbers
one more time. Only after that passes do you strip the debug instrumentation
and rebuild the clean version.

## Step 6 — Report honestly

State exactly what you personally verified (which sizes/states, with what
evidence) versus what you're asking the user to confirm because you
couldn't check it yourself (real device, real Photos library, etc.). Never
phrase a self-verified fix as "should work, please test" — say what you
saw. Never phrase an unverified change as done.
