import SwiftUI


// MARK: - Reusable AppInputField
struct AppInputField<Title: View>: View {
    let iconSystemName: String? // optional icon
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let digitsOnly: Bool
    let cornerRadius: CGFloat
    let title: Title // can be EmptyView

    @FocusState private var isFocused: Bool

    init(iconSystemName: String? = nil,
         placeholder: String,
         text: Binding<String>,
         isSecure: Bool = false,
         digitsOnly: Bool = false,
         cornerRadius: CGFloat = 12,
         @ViewBuilder title: () -> Title = { EmptyView() }) {
        self.iconSystemName = iconSystemName
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.digitsOnly = digitsOnly
        self.cornerRadius = cornerRadius
        self.title = title()
    }

    var body: some View {
        // Keep constants simple for the compiler
        let corner = cornerRadius
        let fillOpacity = isFocused ? 0.35 : 0.25
        let scale: CGFloat = isFocused ? 1.03 : 1.0

        VStack(alignment: .leading, spacing: 6) {
            title

            HStack(spacing: iconSystemName == nil ? 0 : 12) {
                if let name = iconSystemName {
                    Image(systemName: name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white.opacity(0.9))
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .textContentType(.password)
                    } else {
                        TextField(placeholder, text: $text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.username)
                            .keyboardType(digitsOnly ? .numberPad : .default)
                    }
                }
                .foregroundColor(.white)
                .accentColor(.white)
                .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                FocusCapsule(focused: isFocused, corner: corner, fillOpacity: fillOpacity)
            )
            .scaleEffect(scale, anchor: .center)
            .shadow(color: Color.black.opacity(isFocused ? 0.28 : 0.0), radius: isFocused ? 12 : 0, x: 0, y: 8)
            .zIndex(isFocused ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.9, blendDuration: 0), value: isFocused)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
            .onChange(of: text) { newValue in
                guard digitsOnly else { return }
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue { text = filtered }
            }
            .toolbar {
                if digitsOnly && isFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Готово") { isFocused = false }
                    }
                }
            }
        }
    }

    // Encapsulated helper keeps the component standalone for reuse
    private struct FocusCapsule: View {
        let focused: Bool
        let corner: CGFloat
        let fillOpacity: Double

        var body: some View {
            let base = RoundedRectangle(cornerRadius: corner)
            ZStack {
                base.fill(Color.white.opacity(fillOpacity))
                // Base hairline
                base.stroke(Color.white.opacity(0.35), lineWidth: 1)
                if focused {
                    // Crisp white rim (bright)
                    base.stroke(Color.white.opacity(0.98), lineWidth: 2)
                    // Primary soft halo
                    base.stroke(Color.white.opacity(0.50), lineWidth: 6)
                        .blur(radius: 10)
                    // Secondary outer halo
                    base.stroke(Color.white.opacity(0.22), lineWidth: 12)
                        .blur(radius: 18)
                    // Faint outermost veil
                    base.stroke(Color.white.opacity(0.10), lineWidth: 18)
                        .blur(radius: 26)
                    // Inner sheen (glass effect)
                    base.stroke(Color.white.opacity(0.18), lineWidth: 1)
                        .blendMode(.overlay)
                }
            }
        }
    }
}
