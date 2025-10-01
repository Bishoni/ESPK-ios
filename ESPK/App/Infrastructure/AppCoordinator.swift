import SwiftUI

// Экранные состояния приложения
public enum AppScreen {
    case welcome
    case main
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
        case .welcome:
            return .brandDeep
        case .main:
            return .glassLight
        }
    }
}
