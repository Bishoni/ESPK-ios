import SwiftUI

@main
struct ESPKApp: App {
    // Глобальные роутеры/координаторы приложения
    @StateObject private var bgRouter = AppBackgroundRouter(style: .brandSoft)
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Фон — единый слой под любым экраном; стиль управляется через AppCoordinator -> bgRouter
                AppBackgroundSwitcher(router: bgRouter)
                    .ignoresSafeArea()

                // Контент в зависимости от текущего экрана
                Group {
                    switch appCoordinator.currentScreen {
                    case .welcome:
                        WelcomeView(onContinue: {
                            appCoordinator.navigate(to: .main)
                        })
                        .transition(.opacity)

                    case .main:
                        MainView(onLogout: {
                            appCoordinator.navigate(to: .welcome)
                        })
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.45), value: appCoordinator.currentScreen)
            }
            .environmentObject(bgRouter)
            .environmentObject(appCoordinator)
            .onChange(of: appCoordinator.currentScreen) { newScreen in
                // Синхронизирует фон со сменой экрана
                let style = appCoordinator.backgroundStyle(for: newScreen)
                withAnimation(.smooth(duration: 0.9)) {
                    bgRouter.style = style
                }
            }
            .task {
                // Устанавливает начальный стиль фона
                bgRouter.style = appCoordinator.backgroundStyle(for: appCoordinator.currentScreen)
            }
        }
    }
}
