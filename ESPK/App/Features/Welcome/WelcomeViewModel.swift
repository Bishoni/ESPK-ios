import Foundation
import SwiftUI
import OSLog

/// ViewModel экрана приветствия. Отвечает за действия пользователя (нажатия),
/// состояние доступности кнопки и телеметрию. Не тянет данные и не трогает UI.
@MainActor
public final class WelcomeViewModel: ObservableObject {

    // MARK: - Публичные состояния (можно биндинговать к UI)
    @Published public private(set) var isButtonEnabled: Bool = true
    @Published public private(set) var isProcessing: Bool = false

    // MARK: - Конфигурация поведения
    private let enableHaptics: Bool
    private let tapCooldown: TimeInterval
    private let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle

    // MARK: - Инфраструктура
    private let logger: Logger
    private let onContinue: () -> Void

    // MARK: - Инициализация
    /// - Parameters:
    ///   - enableHaptics: включать ли тактильную отдачу при нажатии
    ///   - tapCooldown: защита от дабл-тапа/спама (секунды)
    ///   - feedbackStyle: стиль хаптики
    ///   - logger: OSLog-логгер; по умолчанию создаётся свой
    ///   - onContinue: колбэк «перейти далее»; выполняется на главном потоке
    public init(
        enableHaptics: Bool = true,
        tapCooldown: TimeInterval = 0.35,
        feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        logger: Logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.espk.ESPK",
            category: "WelcomeVM"
        ),
        onContinue: @escaping () -> Void
    ) {
        self.enableHaptics = enableHaptics
        self.tapCooldown = tapCooldown
        self.feedbackStyle = feedbackStyle
        self.logger = logger
        self.onContinue = onContinue
    }

    // MARK: - Жизненный цикл
    /// Сбрасывает временные флаги при появлении экрана.
    public func onAppearReset() {
        isButtonEnabled = true
        isProcessing = false
    }

    // MARK: - Действия пользователя
    /// Обрабатывает нажатие на кнопку «Продолжить».
    /// Делает хаптику, защищает от дабл-тапов и вызывает внешний колбэк.
    public func onContinueTap() {
        guard isButtonEnabled, !isProcessing else {
            logger.debug("WelcomeVM.onContinueTap: ignored (enabled=\(self.isButtonEnabled), processing=\(self.isProcessing))")
            return
        }

        isProcessing = true
        isButtonEnabled = false
        logger.log("WelcomeVM.onContinueTap: proceed")

        if enableHaptics {
            UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
        }

        // Даём системе применить нажатие и анимацию, затем зовём колбэк.
        DispatchQueue.main.async { [onContinue] in
            onContinue()
        }

        // Разрешает повторное нажатие через небольшой интервал.
        DispatchQueue.main.asyncAfter(deadline: .now() + tapCooldown) { [weak self] in
            guard let self else { return }
            self.isProcessing = false
            self.isButtonEnabled = true
        }
    }
}
