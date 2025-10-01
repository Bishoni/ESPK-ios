import SwiftUI

// MARK: - Styles
public enum AppBackgroundStyle: Equatable {
    case brandSoft   // мягкий брендовый (по умолчанию)
    case brandDeep   // насыщённый, с глубокой виньеткой
    case glassLight  // светлый «стеклянный» фон с материалом
    case neutral     // нейтральный системный фон
    case slate       // тёмно‑серый градиент (OLED‑friendly)
}

// MARK: - Central Router (Single Source of Truth)
/// Хранит текущий стиль фона приложения. Экран/меню меняет `style`,
/// а Switcher плавно анимирует переход между стилями.
public final class AppBackgroundRouter: ObservableObject {
    @Published public var style: AppBackgroundStyle
    public init(style: AppBackgroundStyle = .brandSoft) { self.style = style }
}

// MARK: - Reusable Background (Renderer)
/// Рисует конкретный стиль фона без анимации.
public struct AppBackground: View {
    public let style: AppBackgroundStyle

    public init(style: AppBackgroundStyle = .brandSoft) { self.style = style }

    public var body: some View {
        GeometryReader { geo in
            Group {
                switch style {
                case .brandSoft:  brandSoft()
                case .brandDeep:  brandDeep()
                case .glassLight: glassLight()
                case .neutral:    neutral()
                case .slate:      slate()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Centralized Switcher (Animated transitions)
/// Размещается под контентом экрана. Слушает `router.style` и
/// выполняет плавный переход (кросс‑фейд + лёгкий масштаб) между стилями.
public struct AppBackgroundSwitcher: View {
    @ObservedObject private var router: AppBackgroundRouter

    // Внутреннее состояние для двухслойной анимации
    @State private var fromStyle: AppBackgroundStyle
    @State private var progress: CGFloat = 0.0

    // Параметры анимации (вынесены явно для предсказуемости)
    private let animation: Animation
    private let duration: Double
    private let scale: CGFloat

    public init(router: AppBackgroundRouter,
                animation: Animation = .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 1.2),
                duration: Double = 1.2,
                scale: CGFloat = 1.002) {
        self.router = router
        self._fromStyle = State(initialValue: router.style)
        self.animation = animation
        self.duration = duration
        self.scale = scale
    }

    public var body: some View {
        ZStack {
            // Easing for visually smoother tail
            let p = max(0.0, min(1.0, progress))
            let eased = p * p * p * (p * (p * 6 - 15) + 10) // smootherstep

            // Old layer (stays visible and fades out by eased progress)
            AppBackground(style: fromStyle)
                .opacity(1.0 - eased)

            // Interpolated gradient layer to smooth color shift between styles
            let fromColors = baseGradientColors(for: fromStyle)
            let toColors   = baseGradientColors(for: router.style)
            let mix1 = lerpColor(fromColors.0, toColors.0, t: eased)
            let mix2 = lerpColor(fromColors.1, toColors.1, t: eased)
            LinearGradient(colors: [mix1, mix2], startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.65 * eased)
                .ignoresSafeArea()

            // New layer (appears with slight scale)
            AppBackground(style: router.style)
                .scaleEffect(1.0 + (scale - 1.0) * eased)
                .opacity(eased)

            // Transition veils (material, multiply, vignette) bound to eased progress
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.10 * eased)
                .ignoresSafeArea()

            Color.black
                .opacity(0.04 * eased)
                .blendMode(.multiply)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color.black.opacity(0.12 * eased), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
            .blendMode(.multiply)
            .ignoresSafeArea()
        }
        .compositingGroup()
        .ignoresSafeArea()
        .animation(animation, value: progress)
        .onChange(of: router.style) { _ in
            // Стартуем плавную анимацию прогресса 0 → 1
            withAnimation(animation) { progress = 1.0 }
        }
        .onChange(of: progress) { value in
            // Когда прогресс фактически дошёл до 1.0 — фиксируем слой и сбрасываем прогресс без анимации
            if value >= 0.999 && fromStyle != router.style {
                var t = Transaction(); t.disablesAnimations = true
                withTransaction(t) {
                    fromStyle = router.style
                    progress = 0.0
                }
            }
        }
    }
}

// MARK: - Color tween helpers
private func baseGradientColors(for style: AppBackgroundStyle) -> (Color, Color) {
    switch style {
    case .brandSoft:
        return (AppColors.corpPrimary.opacity(0.85), AppColors.corpSecondary.opacity(0.85))
    case .brandDeep:
        return (AppColors.corpPrimary, AppColors.corpSecondary)
    case .glassLight:
        return (Color(.systemBackground), Color(.secondarySystemBackground))
    case .neutral:
        return (Color.white, Color.white.opacity(0.85))
    case .slate:
        return (AppColors.corpDarkGray, AppColors.corpGray.opacity(0.65))
    }
}

private func lerpColor(_ a: Color, _ b: Color, t: CGFloat) -> Color {
    #if os(iOS)
    // Attempt to get RGBA components in sRGB
    let ua = UIColor(a)
    let ub = UIColor(b)
    var r1: CGFloat = 0, g1: CGFloat = 0, bl1: CGFloat = 0, a1: CGFloat = 0
    var r2: CGFloat = 0, g2: CGFloat = 0, bl2: CGFloat = 0, a2: CGFloat = 0
    ua.getRed(&r1, green: &g1, blue: &bl1, alpha: &a1)
    ub.getRed(&r2, green: &g2, blue: &bl2, alpha: &a2)
    let r = r1 + (r2 - r1) * t
    let g = g1 + (g2 - g1) * t
    let b = bl1 + (bl2 - bl1) * t
    let a = a1 + (a2 - a1) * t
    return Color(red: r, green: g, blue: b, opacity: a)
    #else
    // Fallback: simple opacity mix if platform Color→RGBA not available
    return a.opacity(Double(1 - t)) .overlay(b.opacity(Double(t))) as! Color
    #endif
}

// MARK: - Private builders for concrete backgrounds
private extension AppBackground {
    // Мягкий брендовый: градиент фирменных синих + светлая подсветка + мягкая виньетка + тонкий материал
    func brandSoft() -> some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.corpPrimary.opacity(0.85), AppColors.corpSecondary.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.white.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 280
            )
            RadialGradient(
                colors: [Color.black.opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 360
            )
            .blendMode(.multiply)
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.18)
        }
    }

    // Насыщённый брендовый: вертикальный градиент + две тёмные дуги для глубины
    func brandDeep() -> some View {
        ZStack {
            let orientations: [(UnitPoint, UnitPoint)] = [
                (.topLeading, .bottomTrailing),
                (.top, .bottom),
                (.leading, .trailing),
                (.topTrailing, .bottomLeading)
            ]
            let chosen = orientations.randomElement() ?? (.topLeading, .bottomTrailing)
            LinearGradient(
                colors: [AppColors.corpPrimary.opacity(0.95), AppColors.corpSecondary.opacity(0.95)],
                startPoint: chosen.0,
                endPoint: chosen.1
            )
            .saturation(1.1)
            .contrast(1.05)
            Circle()
                .fill(AppColors.corpSecondary.opacity(0.32))
                .scaleEffect(2.1)
                .offset(x: 60, y: 260)
                .blendMode(.multiply)
                .blur(radius: 1)
            Circle()
                .fill(AppColors.corpSecondary.opacity(0.28))
                .scaleEffect(1.7)
                .offset(x: 90, y: 60)
                .blendMode(.multiply)
                .blur(radius: 1)
            RadialGradient(
                colors: [Color.white.opacity(0.06), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 220
            )
        }
    }

    // Светлый «стеклянный»: нейтральный фон + материал и деликатные подсветки
    func glassLight() -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [AppColors.corpPrimary.opacity(0.10), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 260
            )
            RadialGradient(
                colors: [AppColors.corpSecondary.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 320
            )
            Rectangle()
                .fill(.thinMaterial)
                .opacity(0.35)
        }
    }

    // Нейтральный: системный фон с лёгкой верхней подсветкой
    func neutral() -> some View {
        ZStack {
            Color(.systemBackground)
            LinearGradient(
                colors: [Color.white.opacity(0.25), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    // Тёмный сланцевый: плавный серый градиент + мягкая виньетка
    func slate() -> some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.corpDarkGray, AppColors.corpGray.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.black.opacity(0.28), .clear],
                center: .bottom,
                startRadius: 0,
                endRadius: 380
            )
        }
    }
}

// MARK: - Previews
#Preview("Single: brandSoft") { AppBackground(style: .brandSoft).ignoresSafeArea() }
#Preview("Single: brandDeep") { AppBackground(style: .brandDeep).ignoresSafeArea() }
#Preview("Single: glassLight") { AppBackground(style: .glassLight).ignoresSafeArea() }
#Preview("Single: neutral") { AppBackground(style: .neutral).ignoresSafeArea() }
#Preview("Single: slate") { AppBackground(style: .slate).ignoresSafeArea() }

#Preview("Switcher Demo") {
    struct Demo: View {
        @StateObject private var router = AppBackgroundRouter(style: .brandSoft)
        var body: some View {
            ZStack(alignment: .bottom) {
                AppBackgroundSwitcher(router: router)

                VStack(spacing: 8) {
                    Picker("Стиль", selection: $router.style) {
                        Text("Soft").tag(AppBackgroundStyle.brandSoft)
                        Text("Deep").tag(AppBackgroundStyle.brandDeep)
                        Text("Glass").tag(AppBackgroundStyle.glassLight)
                        Text("Neutral").tag(AppBackgroundStyle.neutral)
                        Text("Slate").tag(AppBackgroundStyle.slate)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
    return Demo()
}
