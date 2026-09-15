import SwiftUI

/// Flips a slider's drag direction without touching the underlying value's
/// sign convention anywhere else (pipeline, persistence, reset-to-neutral
/// all stay untouched) — just how dragging it left/right maps to the value.
extension Binding where Value == Double {
    var negated: Binding<Double> {
        Binding(get: { -wrappedValue }, set: { wrappedValue = -$0 })
    }
}
