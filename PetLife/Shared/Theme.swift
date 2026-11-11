import SwiftUI

// Neutral login and home tokens; functional areas use the palettes below.
enum PetTheme {
    static let ink = Color(white: 0.08)
    static let accent = ink
    static let pine = ink
    static let gold = Color(white: 0.48)
    static let cream = Color.white
    static let softBackground = Color.white
    static let surface = Color.white
    static let border = Color(white: 0.90)
    static let secondaryInk = Color(white: 0.40)
    static let radius: CGFloat = 22
}

extension AccentToken {
    var color: Color { PetTheme.ink }
}

struct PetCardSurface: ViewModifier {
    @Environment(\.petPalette) private var palette
    func body(content: Content) -> some View {
        content
            .background(palette.surface, in: RoundedRectangle(cornerRadius: PetTheme.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: PetTheme.radius, style: .continuous).stroke(palette.border, lineWidth: 1))
    }
}

extension View {
    func petCard() -> some View { modifier(PetCardSurface()) }
}

struct PetPrimaryButtonStyle: ButtonStyle {
    @Environment(\.petPalette) private var palette
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(isEnabled ? palette.ink : palette.secondaryInk)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(palette.surface, in: Capsule())
            .overlay(Capsule().stroke(palette.border, lineWidth: 1.2))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}


/// Feature colors keep every page white, with a vivid action color and readable tonal text.
struct PetPalette {
    let accent: Color
    let ink: Color
    let secondaryInk: Color
    let surface: Color
    let border: Color
    let onAccent: Color
    let line: Color
    var pine: Color { accent }
    var gold: Color { ink }
    var cream: Color { .white }
    var softBackground: Color { .white }

    static let neutral = PetPalette(accent: PetTheme.ink, ink: PetTheme.ink,
        secondaryInk: PetTheme.secondaryInk, surface: PetTheme.surface,
        border: PetTheme.border, onAccent: .white, line: PetTheme.ink)
    static let album = PetPalette(accent: Color(hex: 0x55AAFF), ink: .black,
        secondaryInk: .black, surface: Color(hex: 0xF3F8FF),
        border: .black, onAccent: .black, line: .black)
    static let services = PetPalette(accent: Color(hex: 0x20D477), ink: .black,
        secondaryInk: .black, surface: Color(hex: 0xF2FBF6),
        border: .black, onAccent: .black, line: .black)
    static let social = PetPalette(accent: Color(hex: 0xFFD52D), ink: .black,
        secondaryInk: .black, surface: Color(hex: 0xFFFBEC),
        border: .black, onAccent: .black, line: .black)
    // Home entrances use white cards and colored text/linework independently of their destinations.
    private static func shortcut(_ color: Color) -> PetPalette {
        PetPalette(accent: color, ink: color, secondaryInk: color,
                   surface: .white, border: color, onAccent: color, line: color)
    }
    static let albumShortcut = shortcut(Color(hex: 0x1769EF))
    static let servicesShortcut = shortcut(Color(hex: 0x079A50))
    static let socialShortcut = shortcut(Color(hex: 0xB88700))

    static let profile = PetPalette(accent: .black, ink: .black,
        secondaryInk: .black, surface: .white,
        border: .black, onAccent: .black, line: .black)
}

private struct PetPaletteKey: EnvironmentKey {
    static let defaultValue = PetPalette.neutral
}

extension EnvironmentValues {
    var petPalette: PetPalette {
        get { self[PetPaletteKey.self] }
        set { self[PetPaletteKey.self] = newValue }
    }
}

extension View {
    func petPalette(_ palette: PetPalette) -> some View {
        environment(\.petPalette, palette)
            .tint(palette.ink)
            .foregroundStyle(palette.ink)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255, opacity: 1)
    }
}


private struct PetNavigationTitle: ViewModifier {
    @Environment(\.locale) private var appLocale
    @Environment(\.petPalette) private var palette
    let title: String
    func body(content: Content) -> some View {
        let _ = appLocale
        content.navigationTitle(L10n.text(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.text(title)).font(.headline).foregroundStyle(palette.ink)
                        .accessibilityAddTraits(.isHeader)
                }
            }
    }
}

extension View {
    func petNavigationTitle(_ title: String) -> some View {
        modifier(PetNavigationTitle(title: title))
    }
}


struct PetCompactButtonStyle: ButtonStyle {
    @Environment(\.petPalette) private var palette
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isEnabled ? palette.ink : palette.secondaryInk)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(palette.border, lineWidth: 1))
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}
