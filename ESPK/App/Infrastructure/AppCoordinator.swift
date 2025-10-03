import SwiftUI

// Экранные состояния приложения
public enum AppScreen {
    case placeholder
    
    case welcome
    case login
}

// Координатор, отвечающий за текущее состояние приложения
public final class AppCoordinator: ObservableObject {
    @Published public private(set) var currentScreen: AppScreen = .welcome

    public init() {}

    // Навигация между экранами
    public func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentScreen = screen
        }
    }

    // Определяет стиль фона для конкретного экрана
    public func backgroundStyle(for screen: AppScreen) -> AppBackgroundStyle {
        switch screen {
        case .placeholder:
            return .brandDeep
        case .welcome:
            return .brandDeep
        case .login:
            return .brandSoft
        }
    }
}
