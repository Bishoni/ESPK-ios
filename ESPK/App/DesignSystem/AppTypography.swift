import SwiftUI

public enum AppTypography {
    // Крупные заголовки
    public static let titleLarge = Font.system(size: 34, weight: .bold)
    public static let titleMedium = Font.system(size: 28, weight: .semibold)
    public static let titleSmall = Font.system(size: 22, weight: .semibold)

    // Текстовый блок
    public static let body = Font.system(size: 17, weight: .regular)
    public static let bodyBold = Font.system(size: 17, weight: .semibold)

    // Подписи
    public static let caption = Font.system(size: 13, weight: .regular)
    public static let captionBold = Font.system(size: 13, weight: .semibold)
}
