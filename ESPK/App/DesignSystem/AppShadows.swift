import SwiftUI

public enum AppShadows {
    public static let small = ShadowStyle(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
    public static let medium = ShadowStyle(color: .black.opacity(0.20), radius: 4, x: 0, y: 2)
    public static let strong = ShadowStyle(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    
    // Text-specific shadows
    public static let textSoft = ShadowStyle(color: .black.opacity(0.10), radius: 1, x: 0, y: 1)
    public static let textMedium = ShadowStyle(color: .black.opacity(0.22), radius: 2, x: 0, y: 1)
    public static let textStrong = ShadowStyle(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
    
    // Brand glow shadows for text
    public static let textGlowPrimary = ShadowStyle(color: AppColors.corpPrimary.opacity(0.7), radius: 6, x: 0, y: 0)
    public static let textGlowSecondary = ShadowStyle(color: AppColors.corpSecondary.opacity(0.5), radius: 8, x: 0, y: 0)
}

public struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

private struct AppShadowModifier: ViewModifier {
    let style: ShadowStyle
    func body(content: Content) -> some View {
        content.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

public extension View {
    func appShadow(_ style: ShadowStyle) -> some View {
        modifier(AppShadowModifier(style: style))
    }
    
    func appTextShadow(_ style: ShadowStyle) -> some View {
        modifier(AppShadowModifier(style: style))
    }
}
