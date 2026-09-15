import CoreGraphics

/// Componentwise addition, so a committed panel offset can be combined with
/// an in-progress drag translation.
extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
}

/// Lets a committed drag position (`CGPoint`) be combined with an
/// in-progress drag translation (`CGSize`) directly.
extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
}
