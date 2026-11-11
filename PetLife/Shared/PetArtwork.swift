import SwiftUI

enum PetAnimal: CaseIterable {
    case cat, dog, bird, turtle, rabbit
}

// Resolution-independent brand illustrations. Strokes remain crisp at icon and header sizes.
struct PetDoodle: View {
    @Environment(\.locale) private var appLocale
    @Environment(\.petPalette) private var palette
    var animal: PetAnimal = .cat

    var body: some View {
        let _ = appLocale
        Canvas { context, size in
            let scale = min(size.width, size.height) / 100
            context.translateBy(x: (size.width - 100 * scale) / 2, y: (size.height - 100 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            func stroke(_ build: (inout Path) -> Void) {
                var path = Path()
                build(&path)
                context.stroke(path, with: .color(palette.line), style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))
            }
            func dot(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat = 1.3) {
                context.fill(Path(ellipseIn: CGRect(x: x-radius, y: y-radius, width: radius*2, height: radius*2)), with: .color(palette.line))
            }
            switch animal {
            case .cat:
                stroke { p in
                    p.move(to: CGPoint(x: 26, y: 40))
                    p.addLine(to: CGPoint(x: 25, y: 19)); p.addQuadCurve(to: CGPoint(x: 39,y:29), control: CGPoint(x: 29,y:17))
                    p.addQuadCurve(to: CGPoint(x: 55,y:29), control: CGPoint(x: 47,y:26))
                    p.addQuadCurve(to: CGPoint(x: 67,y:18), control: CGPoint(x: 66,y:15)); p.addLine(to: CGPoint(x: 71,y:44))
                    p.addCurve(to: CGPoint(x: 67,y:62), control1: CGPoint(x: 77,y:51), control2: CGPoint(x: 70,y:59))
                    p.addCurve(to: CGPoint(x: 75,y:82), control1: CGPoint(x: 69,y:69), control2: CGPoint(x: 75,y:73))
                    p.addQuadCurve(to: CGPoint(x: 61,y:85), control: CGPoint(x: 77,y:89)); p.addLine(to: CGPoint(x: 41,y:85))
                    p.addQuadCurve(to: CGPoint(x: 27,y:80), control: CGPoint(x: 25,y:89)); p.addLine(to: CGPoint(x: 31,y:62))
                    p.addQuadCurve(to: CGPoint(x: 26,y:40), control: CGPoint(x: 16,y:51))
                    p.move(to: CGPoint(x: 74,y:79)); p.addCurve(to: CGPoint(x: 89,y:54), control1: CGPoint(x: 99,y:79), control2: CGPoint(x: 99,y:51))
                    p.addCurve(to: CGPoint(x: 86,y:65), control1: CGPoint(x: 76,y:53), control2: CGPoint(x: 78,y:69))
                    p.move(to: CGPoint(x: 40,y:68)); p.addLine(to: CGPoint(x: 38,y:84))
                    p.move(to: CGPoint(x: 55,y:68)); p.addLine(to: CGPoint(x: 56,y:84))
                    p.move(to: CGPoint(x: 17,y:44)); p.addLine(to: CGPoint(x: 9,y:42))
                    p.move(to: CGPoint(x: 18,y:50)); p.addLine(to: CGPoint(x: 10,y:51))
                    p.move(to: CGPoint(x: 72,y:44)); p.addLine(to: CGPoint(x: 81,y:42))
                    p.move(to: CGPoint(x: 72,y:50)); p.addLine(to: CGPoint(x: 80,y:52))
                    p.move(to: CGPoint(x: 43,y:49)); p.addQuadCurve(to: CGPoint(x: 49,y:52), control: CGPoint(x: 45,y:54))
                }
                dot(35,42); dot(57,42); dot(46,48,1.1)
            case .dog:
                stroke { p in
                    p.move(to: CGPoint(x: 31,y:29)); p.addCurve(to: CGPoint(x: 21,y:53), control1: CGPoint(x: 14,y:20), control2: CGPoint(x: 10,y:53))
                    p.addQuadCurve(to: CGPoint(x: 32,y:37), control: CGPoint(x: 30,y:56))
                    p.move(to: CGPoint(x: 31,y:29)); p.addQuadCurve(to: CGPoint(x: 62,y:29), control: CGPoint(x: 47,y:19))
                    p.addCurve(to: CGPoint(x: 74,y:52), control1: CGPoint(x: 82,y:22), control2: CGPoint(x: 86,y:52))
                    p.addQuadCurve(to: CGPoint(x: 63,y:37), control: CGPoint(x: 66,y:57))
                    p.move(to: CGPoint(x: 30,y:43)); p.addQuadCurve(to: CGPoint(x: 29,y:62), control: CGPoint(x: 25,y:58))
                    p.addCurve(to: CGPoint(x: 24,y:83), control1: CGPoint(x: 22,y:70), control2: CGPoint(x: 21,y:79))
                    p.addQuadCurve(to: CGPoint(x: 39,y:84), control: CGPoint(x: 29,y:89)); p.addLine(to: CGPoint(x: 64,y:84))
                    p.addQuadCurve(to: CGPoint(x: 69,y:73), control: CGPoint(x: 75,y:88)); p.addLine(to: CGPoint(x: 63,y:61))
                    p.addQuadCurve(to: CGPoint(x: 64,y:44), control: CGPoint(x: 68,y:55))
                    p.move(to: CGPoint(x: 38,y:68)); p.addLine(to: CGPoint(x: 37,y:84))
                    p.move(to: CGPoint(x: 55,y:68)); p.addLine(to: CGPoint(x: 56,y:84))
                    p.move(to: CGPoint(x: 70,y:78)); p.addQuadCurve(to: CGPoint(x: 85,y:64), control: CGPoint(x: 88,y:80))
                    p.move(to: CGPoint(x: 47,y:53)); p.addQuadCurve(to: CGPoint(x: 39,y:56), control: CGPoint(x: 42,y:61))
                    p.move(to: CGPoint(x: 47,y:53)); p.addQuadCurve(to: CGPoint(x: 55,y:56), control: CGPoint(x: 52,y:61))
                }
                dot(37,44); dot(57,44); dot(47,51,2.2)
            case .bird:
                stroke { p in
                    p.move(to: CGPoint(x: 28,y:48)); p.addCurve(to: CGPoint(x: 61,y:28), control1: CGPoint(x: 25,y:21), control2: CGPoint(x: 53,y:17))
                    p.addQuadCurve(to: CGPoint(x: 69,y:43), control: CGPoint(x: 68,y:33))
                    p.addLine(to: CGPoint(x: 82,y:47)); p.addLine(to: CGPoint(x: 70,y:51))
                    p.addCurve(to: CGPoint(x: 34,y:75), control1: CGPoint(x: 76,y:78), control2: CGPoint(x: 45,y:82))
                    p.addLine(to: CGPoint(x: 15,y:56)); p.addQuadCurve(to: CGPoint(x: 28,y:48), control: CGPoint(x: 13,y:50))
                    p.move(to: CGPoint(x: 29,y:53)); p.addQuadCurve(to: CGPoint(x: 56,y:57), control: CGPoint(x: 53,y:45))
                    p.addQuadCurve(to: CGPoint(x: 33,y:66), control: CGPoint(x: 50,y:72))
                    p.move(to: CGPoint(x: 43,y:78)); p.addLine(to: CGPoint(x: 42,y:88)); p.addLine(to: CGPoint(x: 36,y:89))
                    p.move(to: CGPoint(x: 55,y:78)); p.addLine(to: CGPoint(x: 56,y:88)); p.addLine(to: CGPoint(x: 62,y:89))
                    p.move(to: CGPoint(x: 40,y:23)); p.addQuadCurve(to: CGPoint(x: 34,y:16), control: CGPoint(x: 32,y:19))
                }
                dot(60,40,1.5)
            case .turtle:
                stroke { p in
                    p.addEllipse(in: CGRect(x: 18,y:32,width: 54,height: 39))
                    p.move(to: CGPoint(x: 72,y:49)); p.addCurve(to: CGPoint(x: 84,y:68), control1: CGPoint(x: 96,y:33), control2: CGPoint(x: 100,y:65))
                    p.addLine(to: CGPoint(x: 68,y:64))
                    p.move(to: CGPoint(x: 23,y:67)); p.addQuadCurve(to: CGPoint(x: 32,y:79), control: CGPoint(x: 18,y:82)); p.addLine(to: CGPoint(x: 39,y:71))
                    p.move(to: CGPoint(x: 52,y:70)); p.addQuadCurve(to: CGPoint(x: 62,y:81), control: CGPoint(x: 52,y:85)); p.addLine(to: CGPoint(x: 67,y:67))
                    p.move(to: CGPoint(x: 19,y:52)); p.addLine(to: CGPoint(x: 10,y:58)); p.addLine(to: CGPoint(x: 20,y:60))
                    p.move(to: CGPoint(x: 37,y:42)); p.addLine(to: CGPoint(x: 52,y:40)); p.addLine(to: CGPoint(x: 60,y:52)); p.addLine(to: CGPoint(x: 52,y:63)); p.addLine(to: CGPoint(x: 36,y:61)); p.addLine(to: CGPoint(x: 30,y:51)); p.closeSubpath()
                    p.move(to: CGPoint(x: 37,y:42)); p.addLine(to: CGPoint(x: 31,y:35))
                    p.move(to: CGPoint(x: 52,y:40)); p.addLine(to: CGPoint(x: 57,y:35))
                    p.move(to: CGPoint(x: 60,y:52)); p.addLine(to: CGPoint(x: 71,y:52))
                    p.move(to: CGPoint(x: 36,y:61)); p.addLine(to: CGPoint(x: 29,y:68))
                }
                dot(86,52)
            case .rabbit:
                stroke { p in
                    p.move(to: CGPoint(x: 35,y:43)); p.addCurve(to: CGPoint(x: 44,y:39), control1: CGPoint(x: 15,y:0), control2: CGPoint(x: 43,y:5))
                    p.addCurve(to: CGPoint(x: 55,y:40), control1: CGPoint(x: 41,y:0), control2: CGPoint(x: 67,y:8))
                    p.addCurve(to: CGPoint(x: 67,y:65), control1: CGPoint(x: 80,y:44), control2: CGPoint(x: 78,y:59))
                    p.addQuadCurve(to: CGPoint(x: 70,y:84), control: CGPoint(x: 81,y:85))
                    p.addLine(to: CGPoint(x: 34,y:84)); p.addQuadCurve(to: CGPoint(x: 30,y:64), control: CGPoint(x: 18,y:80))
                    p.addQuadCurve(to: CGPoint(x: 35,y:43), control: CGPoint(x: 17,y:49))
                    p.move(to: CGPoint(x: 40,y:70)); p.addLine(to: CGPoint(x: 39,y:83))
                    p.move(to: CGPoint(x: 56,y:70)); p.addLine(to: CGPoint(x: 57,y:83))
                    p.move(to: CGPoint(x: 72,y:76)); p.addQuadCurve(to: CGPoint(x: 80,y:68), control: CGPoint(x: 90,y:81))
                }
                dot(37,53); dot(59,53); dot(48,60,1.4)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct PetPageHeader: View {
    @Environment(\.locale) private var appLocale
    @Environment(\.petPalette) private var palette
    let title: String
    let subtitle: String
    var animal: PetAnimal = .cat
    var usesNeutralText = false

    var body: some View {
        let _ = appLocale
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text(title))
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(usesNeutralText ? PetTheme.ink : palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.text(subtitle))
                    .font(.subheadline)
                    .foregroundStyle(usesNeutralText ? PetTheme.ink : palette.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PetDoodle(animal: animal).frame(width: 82, height: 88)
        }
        .padding(.vertical, 4)
    }
}

struct PetHeroArtwork: View {
    @Environment(\.locale) private var appLocale
    let name: String
    var width: CGFloat
    var alignment: Alignment = .center

    private var animal: PetAnimal {
        if name.contains("tree") { return .bird }
        if name.contains("profile") { return .turtle }
        if name.contains("social") { return .dog }
        return .cat
    }
    var body: some View {
        let _ = appLocale
        PetDoodle(animal: animal).frame(width: width, height: width, alignment: alignment)
    }
}

struct PetFeatureIcon: View {
    @Environment(\.locale) private var appLocale
    let name: String
    var size: CGFloat = 44
    var body: some View {
        let _ = appLocale
        PetDoodle(animal: name.contains("tree") ? .bird : name.contains("social") ? .dog : .cat)
            .frame(width: size, height: size)
    }
}

struct PetTabIcon: View {
    @Environment(\.locale) private var appLocale
    let name: String
    var body: some View {
        let _ = appLocale
        Image(systemName: name.contains("tree") ? "leaf" : name.contains("social") ? "bubble.left.and.bubble.right" : name.contains("profile") ? "person.crop.circle" : "house")
            .font(.system(size: 21, weight: .regular))
    }
}

// Tags wrap as complete words, including at larger accessibility text sizes.
struct PetFlowLayout: Layout {
    var spacing: CGFloat = 6

    private func arranged(_ subviews: Subviews, width: CGFloat) -> (points: [CGPoint], height: CGFloat) {
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (points, y + rowHeight)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width + spacing }
        return CGSize(width: width, height: arranged(subviews, width: width).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arranged(subviews, width: bounds.width)
        for (index, view) in subviews.enumerated() {
            view.place(at: CGPoint(x: bounds.minX + layout.points[index].x, y: bounds.minY + layout.points[index].y), anchor: .topLeading, proposal: .unspecified)
        }
    }
}
