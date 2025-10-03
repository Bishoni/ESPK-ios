import Foundation
import Combine
import OSLog
import Security

/// Конфигурация экрана логина (явная и легко изменяемая).
enum LoginConfig {
    /// Базовый адрес API. При локальной отладке заменить на нужный.
    static let apiBaseURL: URL = URL(string: "https://example.com")!
    /// Путь логина. Итоговый URL = apiBaseURL.appendingPathComponent(loginPath)
    static let loginPath: String = "/api/login"
    /// Таймаут сетевого запроса (секунды).
    static let requestTimeout: TimeInterval = 15.0
    /// Длина табельного номера (ровно столько цифр).
    static let usernameRequiredDigits: Int = 5
    /// Минимальная длина пароля.
    static let minPasswordLength: Int = 1

    /// Ключи для UserDefaults и Keychain.
    static let defaultsSavedLoginKey: String = "auth.saved_login"
    static let keychainService: String = "com.example.espk.auth"
    static let keychainAccountPassword: String = "auth.saved_password"
}

/// Ошибки аутентификации/валидации.
enum AuthError: LocalizedError {
    case invalidUsernameFormat
    case invalidPasswordFormat
    case network(Error)
    case badStatusCode(Int, serverMessage: String?)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidUsernameFormat:
            return "Некорректный табельный номер: требуется ровно \(LoginConfig.usernameRequiredDigits) цифр."
        case .invalidPasswordFormat:
            return "Некорректный пароль: пустое значение недопустимо."
        case .network(let underlying):
            return "Ошибка сети: \(underlying.localizedDescription)"
        case .badStatusCode(let code, let message):
            if let message, !message.isEmpty {
                return "Ошибка авторизации (\(code)): \(message)"
            } else {
                return "Ошибка авторизации: код \(code)."
            }
        case .unknown:
            return "Неизвестная ошибка."
        }
    }
}

/// Минимальный протокол сервиса авторизации.
/// В текущей постановке JWT не используется: достаточно успешного ответа 2xx.
protocol AuthService {
    func login(username: String, password: String) async throws
}

/// Сетевой сервис по умолчанию (без JWT): POST JSON на /api/login,
/// успех — любой HTTP 2xx.
final class NetworkAuthService: AuthService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.espk", category: "AuthService")

    func login(username: String, password: String) async throws {
        var request = URLRequest(url: LoginConfig.apiBaseURL.appendingPathComponent(LoginConfig.loginPath))
        request.httpMethod = "POST"
        request.timeoutInterval = LoginConfig.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Body: Encodable { let username: String; let password: String }
        request.httpBody = try JSONEncoder().encode(Body(username: username, password: password))

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                logger.error("Ответ без HTTPURLResponse")
                throw AuthError.unknown
            }
            guard (200...299).contains(http.statusCode) else {
                let serverText = String(data: data, encoding: .utf8)
                logger.error("Авторизация отклонена: код \(http.statusCode), сообщение: \(serverText ?? "nil")")
                throw AuthError.badStatusCode(http.statusCode, serverMessage: serverText)
            }
            logger.info("Авторизация успешна (HTTP \(http.statusCode)).")
        } catch {
            throw AuthError.network(error)
        }
    }
}

/// Хранилище учётных данных: UserDefaults для логина, Keychain для пароля.
protocol CredentialsStore {
    var savedLogin: String? { get }
    func save(login: String, password: String) throws
    func clear() throws
    func hasValidCredentials() -> Bool
}

/// Реализация хранилища с Keychain.
final class KeychainCredentialsStore: CredentialsStore {
    private let defaults: UserDefaults
    private let service: String
    private let accountPassword: String

    init(defaults: UserDefaults = .standard,
         service: String = LoginConfig.keychainService,
         accountPassword: String = LoginConfig.keychainAccountPassword) {
        self.defaults = defaults
        self.service = service
        self.accountPassword = accountPassword
    }

    var savedLogin: String? {
        defaults.string(forKey: LoginConfig.defaultsSavedLoginKey)
    }

    func hasValidCredentials() -> Bool {
        guard let login = savedLogin,
              login.count == LoginConfig.usernameRequiredDigits,
              login.allSatisfy(\.isNumber),
              (try? readPassword())?.isEmpty == false
        else {
            return false
        }
        return true
    }

    func save(login: String, password: String) throws {
        defaults.set(login, forKey: LoginConfig.defaultsSavedLoginKey)
        try writePassword(password)
    }

    func clear() throws {
        defaults.removeObject(forKey: LoginConfig.defaultsSavedLoginKey)
        try deletePassword()
    }

    // MARK: - Keychain (пароль)

    private func writePassword(_ password: String) throws {
        try deletePassword() // очищает дубликаты перед insert

        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountPassword,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw keychainError(from: status) }
    }

    private func readPassword() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountPassword,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw keychainError(from: status) }
        guard let data = item as? Data, let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private func deletePassword() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountPassword
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw keychainError(from: status) }
    }

    private func keychainError(from status: OSStatus) -> Error {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [
            NSLocalizedDescriptionKey: (SecCopyErrorMessageString(status, nil) as String?) ?? "Keychain error \(status)"
        ])
    }
}

/// ViewModel логина. Выполняет валидацию, сетевой вызов (без JWT),
/// сохраняет учётные данные, отдаёт событие об успешной авторизации.
@MainActor
final class LoginViewModel: ObservableObject {
    // Внешние зависимости (инъекция)
    private let authService: AuthService
    private let store: CredentialsStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.espk", category: "LoginVM")

    // Публичные реакции вью
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    /// Колбэк, вызываемый при успешной авторизации (для перехода в главный экран).
    private let onAuthorized: () -> Void

    // MARK: - Жизненный цикл

    init(authService: AuthService = NetworkAuthService(),
         store: CredentialsStore = KeychainCredentialsStore(),
         onAuthorized: @escaping () -> Void) {
        self.authService = authService
        self.store = store
        self.onAuthorized = onAuthorized
    }

    /// Проверяет локальные учётные данные и, если они валидны, сразу переводит в главный экран.
    func tryAutoSignIn() {
        guard store.hasValidCredentials(), let saved = store.savedLogin else { return }
        username = saved
        logger.info("Найдены валидные локальные учётные данные. Переход в главный экран.")
        onAuthorized()
    }

    /// Ограничивает ввод табельного номера только цифрами и до нужной длины.
    func normalizeUsernameInput(_ newValue: String) {
        let digitsOnly = newValue.filter(\.isNumber)
        let limited = String(digitsOnly.prefix(LoginConfig.usernameRequiredDigits))
        if limited != username { username = limited }
    }

    /// Валидирует форму.
    private func validate() throws {
        guard username.count == LoginConfig.usernameRequiredDigits, username.allSatisfy(\.isNumber) else {
            throw AuthError.invalidUsernameFormat
        }
        guard password.count >= LoginConfig.minPasswordLength else {
            throw AuthError.invalidPasswordFormat
        }
    }

    /// Вход: валидация -> сеть -> сохранение -> колбэк перехода.
    func signIn() async {
        errorMessage = nil
        do {
            try validate()
            isLoading = true
            defer { isLoading = false }
            try await authService.login(username: username, password: password)
            try store.save(login: username, password: password)
            logger.info("Учётные данные сохранены. Авторизация завершена.")
            onAuthorized()
        } catch let e as AuthError {
            errorMessage = e.localizedDescription
            logger.error("Ошибка авторизации: \(e.localizedDescription, privacy: .public)")
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Неожиданная ошибка авторизации: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Сбрасывает сохранённые креды (например, для ручного выхода).
    func resetCredentials() {
        do {
            try store.clear()
            logger.info("Учётные данные очищены.")
        } catch {
            logger.error("Ошибка очистки учётных данных: \(error.localizedDescription, privacy: .public)")
        }
    }
}
