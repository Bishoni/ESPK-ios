import SwiftUI
import OSLog

/// Экран авторизации в стиле образца:
/// - фон: `hero_resize` с блюром и затемнением;
/// - логотип: `logo` с пружинной анимацией при появлении клавиатуры;
/// - поля в «стеклянных» капсулах с иконками `log`/`pass`;
/// - большая кнопка входа с ProgressView;
/// - лаконичная плашка ошибки.
struct LoginView: View {
    // Видимые настройки внешнего вида.
    private enum UI {
        static let maxCardWidth: CGFloat = 460
        static let cornerRadius: CGFloat = 12
    }

    @EnvironmentObject private var bgRouter: AppBackgroundRouter

    @StateObject private var viewModel: LoginViewModel
    private enum Field: Hashable { case username, password }
    @FocusState private var focusedField: Field?

    @State private var loginFailed = false
    @State private var isKeyboardVisible = false

    // Маршруты вспомогательных действий (регистрация/забыли пароль)
    private let onRegister: () -> Void
    private let onForgot: () -> Void

    init(
        authService: AuthService = NetworkAuthService(),
        store: CredentialsStore = KeychainCredentialsStore(),
        onAuthorized: @escaping () -> Void,
        onRegister: @escaping () -> Void = {},
        onForgot: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: LoginViewModel(
                authService: authService,
                store: store,
                onAuthorized: onAuthorized
            )
        )
        self.onRegister = onRegister
        self.onForgot = onForgot
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ZStack {
                        AppBackgroundSwitcher(router: bgRouter)
                            .ignoresSafeArea()
                            .ignoresSafeArea(.keyboard, edges: .bottom)

                        ScrollView {
                            VStack(spacing: 32) {
                                LoginHeader(isKeyboardVisible: isKeyboardVisible, geo: geo)
                                LoginForm(
                                    viewModel: viewModel,
                                    loginFailed: $loginFailed,
                                    focusedField: $focusedField,
                                    proxy: proxy,
                                    onRegister: onRegister,
                                    onForgot: onForgot,
                                    attemptLogin: attemptLogin,
                                    canSubmit: canSubmit
                                )
                            }
                            .frame(maxWidth: UI.maxCardWidth, alignment: .top)
                            .padding(.horizontal, 24)
                            .frame(width: geo.size.width, alignment: .top)
                            .frame(minHeight: geo.size.height, alignment: .top)
                            .padding(.top, 0)
                            .padding(.bottom, 0)
                        }
                        .contentShape(Rectangle())
                        .ignoresSafeArea(.container, edges: .top)
                        .onTapGesture { dismissKeyboard() }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.username) { _, _ in hideErrorIfNeeded() }
        .onChange(of: viewModel.password) { _, _ in hideErrorIfNeeded() }
        .onAppear {
            viewModel.tryAutoSignIn()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .username
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation { isKeyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation { isKeyboardVisible = false }
        }
    }

    private var canSubmit: Bool {
        !viewModel.username.isEmpty && !viewModel.password.isEmpty
    }

    private func attemptLogin() {
        guard canSubmit && !viewModel.isLoading else { return }
        dismissKeyboard()

        Task {
            withAnimation { loginFailed = false }
            await viewModel.signIn() // onAuthorized вызывается внутри VM
            withAnimation(.spring()) {
                // если ViewModel не заполнил errorMessage — считаем, что вход успешен
                loginFailed = (viewModel.errorMessage?.isEmpty == false)
            }
        }
    }

    private func hideErrorIfNeeded() {
        if loginFailed {
            withAnimation(.spring()) { loginFailed = false }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    private func scrollToField(_ field: Field, in proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { proxy.scrollTo(field, anchor: .center) }
        }
    }

    private struct LoginHeader: View {
        let isKeyboardVisible: Bool
        let geo: GeometryProxy

        var body: some View {
            VStack(spacing: 6) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(geo.size.width * 0.28, 120))
                    .shadow(radius: 8)
                    .offset(y: isKeyboardVisible ? -4 : 0)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 20), value: isKeyboardVisible)

                StyledTextLabel("Вход в систему", fontSize: 34, fontWeight: .bold)
            }
            .padding(.top, 0)
            .animation(.easeOut(duration: 0.3), value: isKeyboardVisible)
        }
    }

    private struct LoginForm: View {
        @ObservedObject var viewModel: LoginViewModel
        @Binding var loginFailed: Bool
        @FocusState.Binding var focusedField: Field?
        let proxy: ScrollViewProxy
        let onRegister: () -> Void
        let onForgot: () -> Void
        let attemptLogin: () -> Void
        let canSubmit: Bool

        var body: some View {
            VStack(spacing: 16) {
                AppInputField(
                    iconSystemName: "person.crop.circle.fill",
                    placeholder: "Введите номер",
                    text: Binding(
                        get: { viewModel.username },
                        set: { viewModel.normalizeUsernameInput($0) }
                    ),
                    isSecure: false,
                    digitsOnly: true
                ) {
                    StyledTextLabel("Табельный номер", fontSize: 18)
                }
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                    scrollToField(.password, in: proxy)
                }
                .id(Field.username)

                AppInputField(
                    iconSystemName: "lock.fill",
                    placeholder: "Введите пароль",
                    text: $viewModel.password,
                    isSecure: true,
                    digitsOnly: false
                ) {
                    StyledTextLabel("Пароль", fontSize: 18)
                }
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { attemptLogin() }
                .id(Field.password)

                Button(action: attemptLogin) {
                    PrimaryActionLabel(isLoading: viewModel.isLoading)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: UI.cornerRadius)
                        .fill(canSubmit && !viewModel.isLoading
                              ? Color.white.opacity(0.95)
                              : Color.gray.opacity(0.3))
                )
                .foregroundColor(canSubmit ? .black : .gray)
                .disabled(!canSubmit || viewModel.isLoading)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)

                if loginFailed {
                    Text("Неверный логин или пароль")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.red)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.top, 4)
                }

                AuthAuxActions(onRegister: onRegister, onForgot: onForgot)
                    .padding(.top, 12)
            }
        }

        private func scrollToField(_ field: Field, in proxy: ScrollViewProxy) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { proxy.scrollTo(field, anchor: .center) }
            }
        }
    }
}

private struct AuthAuxActions: View {
    let onRegister: () -> Void
    let onForgot: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            Button(action: onRegister) {
                StyledTextLabel("Зарегистрироваться", fontSize: 22)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Button(action: onForgot) {
                StyledTextLabel("Забыли пароль?", fontSize: 22)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
}

private struct PrimaryActionLabel: View {
    let isLoading: Bool

    var body: some View {
        ZStack {
            Text("Войти")
                .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
    }
}

// MARK: - Превью
#Preview {
    LoginView(
        onAuthorized: {},
        onRegister: {},
        onForgot: {}
    )
}
