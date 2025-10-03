import SwiftUI

// MARK: - Styled Text Label (Reusable)
struct StyledTextLabel: View {
    let text: String

    // Appearance
    var fontSize: CGFloat = 20
    var fontWeight: Font.Weight = .semibold
    var fontDesign: Font.Design = .rounded
    var fontOverride: Font? = nil
    var font: Font { fontOverride ?? .system(size: fontSize, weight: fontWeight, design: fontDesign) }
    var foreground: Color = .white
    var gradient: LinearGradient? = nil // If provided, it will replace foreground

    // Outline
    var outlineColor: Color = .black
    var outlineOpacity: Double = 0.55
    var outlineWidth: CGFloat = 0.6 // visual thickness in points

    // Shadow strength: .soft / .medium / .strong
    enum ShadowLevel { case soft, medium, strong, none }
    var shadowLevel: ShadowLevel = .medium

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(_ text: String,
         fontSize: CGFloat = 15,
         fontOverride: Font? = nil,
         fontWeight: Font.Weight = .semibold,
         fontDesign: Font.Design = .rounded,
         foreground: Color = .white,
         gradient: LinearGradient? = nil,
         outlineColor: Color = .black,
         outlineOpacity: Double = 0.55,
         outlineWidth: CGFloat = 0.6,
         shadowLevel: ShadowLevel = .medium) {
        self.text = text
        self.fontSize = fontSize
        self.fontOverride = fontOverride
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.foreground = foreground
        self.gradient = gradient
        self.outlineColor = outlineColor
        self.outlineOpacity = outlineOpacity
        self.outlineWidth = outlineWidth
        self.shadowLevel = shadowLevel
    }

    var body: some View {
        let oc = outlineColor.opacity(outlineOpacity)
        let w = outlineWidth
        let diag = outlineWidth * 0.7071 // ~ 1/sqrt(2)

        ZStack {
            // 8-direction outline for cleaner edge
            Text(text).font(font).foregroundStyle(oc).offset(x:  w, y:  0)
            Text(text).font(font).foregroundStyle(oc).offset(x: -w, y:  0)
            Text(text).font(font).foregroundStyle(oc).offset(x:  0, y:  w)
            Text(text).font(font).foregroundStyle(oc).offset(x:  0, y: -w)
            Text(text).font(font).foregroundStyle(oc).offset(x:  diag, y:  diag)
            Text(text).font(font).foregroundStyle(oc).offset(x: -diag, y:  diag)
            Text(text).font(font).foregroundStyle(oc).offset(x:  diag, y: -diag)
            Text(text).font(font).foregroundStyle(oc).offset(x: -diag, y: -diag)

            // Foreground (gradient or solid)
            if let g = gradient, !reduceTransparency {
                g.mask(Text(text).font(font))
                    .modifier(shadowModifier)
            } else {
                Text(text)
                    .font(font)
                    .foregroundStyle(foreground)
                    .modifier(shadowModifier)
            }
        }
    }

    private var shadowModifier: some ViewModifier {
        switch shadowLevel {
        case .none:
            return AnyViewModifier(EmptyModifier())
        case .soft:
            return AnyViewModifier(AppTextShadowModifier(style: AppShadows.textSoft))
        case .medium:
            return AnyViewModifier(AppTextShadowModifier(style: AppShadows.textMedium))
        case .strong:
            return AnyViewModifier(AppTextShadowModifier(style: AppShadows.textStrong))
        }
    }
}

// Helper to allow dynamic modifier selection
struct AnyViewModifier: ViewModifier {
    private let bodyClosure: (Content) -> AnyView
    init<M: ViewModifier>(_ modifier: M) {
        self.bodyClosure = { AnyView($0.modifier(modifier)) }
    }
    func body(content: Content) -> some View { bodyClosure(content) }
}

// Assuming you have a modifier that applies a shadow style
struct AppTextShadowModifier: ViewModifier {
    let style: ShadowStyle
    func body(content: Content) -> some View {
        content.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
