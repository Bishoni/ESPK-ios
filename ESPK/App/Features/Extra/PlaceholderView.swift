import SwiftUI
import OSLog

/// Универсальная заглушка, которую можно вставить в любой экран.
/// Назад: сначала вызывает onBack (если передан), иначе dismiss().
struct PlaceholderView: View {
    // Явная конфигурация, чтобы было легко подправить оформление.
    private enum UI {
        static let cardCornerRadius: CGFloat = 20
        static let cardMaxWidth: CGFloat = 420
        static let verticalSpacing: CGFloat = 16
        static let padding: CGFloat = 24
        static let buttonHeight: CGFloat = 48
        static let showShadow: Bool = true
        static let iconSize: CGFloat = 44
        static let titleSize: CGFloat = 24
        static let subtitleSize: CGFloat = 16
    }

    // Входные параметры — удобно переиспользовать с разными текстами/иконками.
    let title: String
    let message: String
    let systemIconName: String
    let onBack: (() -> Void)?

    // Возврат по системе (NavigationStack / sheet / fullScreenCover).
    @Environment(\.dismiss) private var dismiss

    // Логи — фиксируют показ и действие «Назад».
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.espk",
        category: "PlaceholderView"
    )

    // Значения по умолчанию — «в разработке».
    init(
        title: String = "Раздел в разработке",
        message: String = "Скоро здесь появится функционал.",
        systemIconName: String = "hammer",
        onBack: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemIconName = systemIconName
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            // Слой фона оставляет управление общим стилем за вашим AppBackgroundSwitcher.
            Color.clear

            VStack(spacing: UI.verticalSpacing) {
                Image(systemName: systemIconName)
                    .font(.system(size: UI.iconSize, weight: .semibold))

                Text(title)
                    .font(.system(size: UI.titleSize, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: UI.subtitleSize))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: back) {
                    Text("Назад")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: UI.buttonHeight)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Назад")
            }
            .padding(UI.padding)
            .frame(maxWidth: UI.cardMaxWidth)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: UI.cardCornerRadius, style: .continuous))
            .shadow(radius: UI.showShadow ? 12 : 0)
            .padding(.horizontal, 24)
        }
        .onAppear {
            logger.info("Показана заглушка: \(self.title, privacy: .public)")
        }
    }

    // Вызывает переданный колбэк, иначе откатывает системной навигацией.
    private func back() {
        if let onBack {
            onBack()
            logger.info("Навигация назад через onBack().")
        } else {
            dismiss()
            logger.info("Навигация назад через environment dismiss().")
        }
    }
}

// MARK: - Примеры запуска (для быстрого визуального теста)
#Preview("NavigationStack push") {
    NavigationStack {
        VStack(spacing: 20) {
            Text("Хост-экран")
            NavigationLink("Открыть заглушку") {
                PlaceholderView()
            }
        }
        .padding()
    }
}

#Preview("Sheet") {
    struct Host: View {
        @State private var show = true
        var body: some View {
            Button("Показать заглушку") { show = true }
                .sheet(isPresented: $show) {
                    // В модалках dismiss() сработает автоматически,
                    // но колбэк показывает альтернативу (например, для кастомных координаторов).
                    PlaceholderView(onBack: { show = false })
                }
        }
    }
    return Host()
}
