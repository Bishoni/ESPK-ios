import SwiftUI

public enum AppAnimations {
    // Стандартные плавные
    public static let easeFast  = Animation.easeInOut(duration: 0.20)
    public static let ease      = Animation.easeInOut(duration: 0.35)
    public static let easeSlow  = Animation.easeInOut(duration: 0.60)

    // Пружинки
    public static let springSoft   = Animation.spring(response: 0.35, dampingFraction: 0.80, blendDuration: 0.20)
    public static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.70, blendDuration: 0.15)
    public static let springBouncy = Animation.interactiveSpring(response: 0.45, dampingFraction: 0.65, blendDuration: 0.10)
}
