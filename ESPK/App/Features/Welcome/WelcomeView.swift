import SwiftUI

// MARK: - Конфигурация экрана приветствия (только явные токены)
private enum WelcomeConfig {

    // Контент (без массивов строк)
    static let titleText: LocalizedStringKey = "Добро пожаловать"
    static let bodyText: LocalizedStringKey = "в Единую систему\nпроизводственного\nконтроля"

    // Ресурсы
    static let appLogoAssetName: String = "ESPK" // добавить изображение в Assets.xcassets

    // Layout/Style токены (в явном виде)
    static let logoSize: CGSize = .init(width: 140, height: 140)
    static let titleFont: Font = .system(size: 32, weight: .heavy, design: .rounded)
    static let bodyFont: Font  = .system(size: 28, weight: .semibold, design: .rounded)

    static let lineSpacing: CGFloat = 4
    static let textMaxWidth: CGFloat = 340
    static let cardCornerRadius: CGFloat = 18
    static let topPadding: CGFloat = 24
    static let spacerAfterLogo: CGFloat = 40
    static let horizontalPadding: CGFloat = 24
    static let bottomPadding: CGFloat = 32

    static let primaryButtonDiameter: CGFloat = 88
    static let primaryChevronSize: CGFloat = 28
    static let appearAnimationDuration: Double = 0.55
    static let cardMaterialBaseOpacity: Double = 0.22
    static let cardStrokeOpacity: Double = 0.14

    static let cardOuterStrokeOpacity: Double = 0.14
    static let cardInnerStrokeOpacity: Double = 0.28
}

// MARK: - Основная вью
public struct WelcomeView: View {
    @EnvironmentObject private var bgRouter: AppBackgroundRouter
    @Environment(\.dynamicTypeSize) private var dynamicType
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var showBadge: Bool = false
    @State private var showButton: Bool = false
    private let onContinue: () -> Void

    public init(onContinue: @escaping () -> Void = {}) {
        self.onContinue = onContinue
    }

    public var body: some View {
        ZStack {
            AppBackgroundSwitcher(router: bgRouter)

            GeometryReader { geo in
                let logoSize = min(geo.size.width * 0.54, 300)
                let isPortrait = geo.size.height >= geo.size.width
                let textTopPadding = isPortrait ? (logoSize * 0.35 + 12) : 0

                ZStack {
                    if isPortrait {
                        VStack {
                            Image("WelcomePBOT")
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: logoSize, height: logoSize)
                                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                                .opacity(showBadge ? 1 : 0)
                                .scaleEffect(showBadge ? 1.0 : 0.97)
                                .offset(y: showBadge ? 0 : -6)
                                .animation(.smooth(duration: 0.55), value: showBadge)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 8)
                    }

                    VStack(spacing: 24) {
                        Spacer()

                        VStack(spacing: WelcomeConfig.lineSpacing) {
                            Text(WelcomeConfig.titleText)
                                .font(WelcomeConfig.titleFont)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .appTextShadow(AppShadows.textStrong)
                                .appTextShadow(AppShadows.textGlowPrimary)
                                .minimumScaleFactor(0.9)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .layoutPriority(1)

                            Text(WelcomeConfig.bodyText)
                                .font(WelcomeConfig.bodyFont)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .appTextShadow(AppShadows.textSoft)
                                .appTextShadow(AppShadows.textGlowSecondary)
                                .minimumScaleFactor(0.85)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .layoutPriority(1)
                        }
                        .frame(maxWidth: WelcomeConfig.textMaxWidth)
                        .padding(.horizontal, WelcomeConfig.horizontalPadding)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if reduceTransparency {
                                    RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius)
                                        .fill(Color(.systemBackground).opacity(0.72))
                                } else {
                                    RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius)
                                        .fill(.ultraThinMaterial)
                                        .opacity(WelcomeConfig.cardMaterialBaseOpacity)
                                }
                            }
                        )
                        // Внешний градиентный hairline
                        .overlay(
                            RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(WelcomeConfig.cardOuterStrokeOpacity),
                                            Color.white.opacity(WelcomeConfig.cardOuterStrokeOpacity * 0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        // Внутренний фирменный акцент
                        .overlay(
                            RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius - 1, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AppColors.corpPrimary.opacity(0.22),
                                            AppColors.corpSecondary.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .blendMode(.overlay)
                                .opacity(WelcomeConfig.cardInnerStrokeOpacity)
                        )
                        // Мягкий верхний блеск для глубины
                        .overlay(
                            RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.10), Color.white.opacity(0.04), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius, style: .continuous))
                        )
                        // Внутренняя тень (inner shadow) сверху/снизу — аккуратная глубина
                        .overlay(
                            RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius, style: .continuous)
                                .stroke(Color.black.opacity(0.25), lineWidth: 4)
                                .blur(radius: 4)
                                .offset(y: 1)
                                .mask(
                                    LinearGradient(
                                        colors: [.black, .clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                    .mask(
                                        RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius, style: .continuous)
                                    )
                                )
                                .opacity(0.35)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius, style: .continuous)
                                .stroke(Color.black.opacity(0.20), lineWidth: 3)
                                .blur(radius: 3)
                                .offset(y: -1)
                                .mask(
                                    LinearGradient(
                                        colors: [.clear, .black],
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )
                                    .mask(
                                        RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius, style: .continuous)
                                    )
                                )
                                .opacity(0.28)
                        )
                        // Очень деликатное внешнее свечение под брендовую палитру
                        .overlay(
                            RoundedRectangle(cornerRadius: WelcomeConfig.cardCornerRadius + 2, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AppColors.corpPrimary.opacity(0.14),
                                            AppColors.corpSecondary.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .blur(radius: 12)
                                .opacity(0.35)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                        .fixedSize(horizontal: false, vertical: true)
                        .compositingGroup()

                        // Кнопка сразу под текстом
                        PrimaryCircleButton(action: handleContinue,
                                            diameter: WelcomeConfig.primaryButtonDiameter,
                                            chevronPointSize: WelcomeConfig.primaryChevronSize)
                            .opacity(showButton ? 1 : 0)
                            .offset(y: showButton ? 0 : 12)
                            .scaleEffect(showButton ? 1.0 : 0.98)
                            .animation(.smooth(duration: 0.55), value: showButton)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, textTopPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .onAppear {
            bgRouter.style = .brandDeep
            showBadge = false
            showButton = false
            DispatchQueue.main.async {
                withAnimation(.smooth(duration: 0.55)) { showBadge = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.smooth(duration: 0.60)) { showButton = true }
                }
            }
        }
    }

    private func handleContinue() {
        onContinue()
    }
}

// MARK: - Подвью: Кнопка продолжения
private struct PrimaryCircleButton: View {
    let action: () -> Void
    let diameter: CGFloat
    let chevronPointSize: CGFloat

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: chevronPointSize, weight: .bold))
                .foregroundStyle(AppColors.corpPrimary)
                .accessibilityHidden(true)
        }
        .buttonStyle(PrimaryCircleButtonStyle(diameter: diameter))
        .accessibilityLabel("Продолжить")
    }
}

private struct PrimaryCircleButtonStyle: ButtonStyle {
    let diameter: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        return ZStack {
            // Base soft-white fill with subtle diagonal gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Specular gloss from top-left (very subtle)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.40), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .opacity(0.55)

            // Fine inner rim (gives depth)
            Circle()
                .stroke(Color.white.opacity(0.70), lineWidth: 1)

            // Inner shadow on the lower arc (neumorphic hint)
            Circle()
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
                .blur(radius: 1.2)
                .offset(y: 1)
                .mask(Circle().stroke(lineWidth: 2))

            // Brand halo ring (reacts on press)
            Circle()
                .stroke(AppColors.corpPrimary.opacity(pressed ? 0.28 : 0.16), lineWidth: pressed ? 6 : 8)
                .blur(radius: pressed ? 6 : 10)

            // Chevron
            configuration.label
                .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .appShadow(pressed ? AppShadows.small : AppShadows.medium)
        .animation(.easeInOut(duration: 0.18), value: pressed)
    }
}


// MARK: - Preview
#Preview("Welcome Screen") {
    let router = AppBackgroundRouter(style: .brandSoft)
    return WelcomeView()
        .environmentObject(router)
}
