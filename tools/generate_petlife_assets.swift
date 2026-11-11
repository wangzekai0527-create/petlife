import AppKit
import Foundation

struct Palette {
    static let accent = NSColor(red: 0.86, green: 0.24, blue: 0.22, alpha: 1)
    static let pine = NSColor(red: 0.10, green: 0.36, blue: 0.26, alpha: 1)
    static let cream = NSColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1)
    static let gold = NSColor(red: 0.95, green: 0.75, blue: 0.24, alpha: 1)
    static let ink = NSColor(red: 0.16, green: 0.17, blue: 0.22, alpha: 1)
    static let peach = NSColor(red: 0.95, green: 0.62, blue: 0.28, alpha: 1)
    static let sky = NSColor(red: 0.34, green: 0.55, blue: 0.88, alpha: 1)
    static let plum = NSColor(red: 0.56, green: 0.26, blue: 0.55, alpha: 1)
    static let mint = NSColor(red: 0.24, green: 0.71, blue: 0.58, alpha: 1)
    static let sand = NSColor(red: 0.93, green: 0.82, blue: 0.67, alpha: 1)
    static let cocoa = NSColor(red: 0.47, green: 0.33, blue: 0.24, alpha: 1)
    static let blush = NSColor(red: 0.95, green: 0.78, blue: 0.78, alpha: 1)
    static let cloud = NSColor(red: 1.00, green: 0.99, blue: 0.97, alpha: 1)
    static let mist = NSColor(red: 0.90, green: 0.92, blue: 0.95, alpha: 1)
}

struct AssetDefinition {
    let name: String
    let size: CGSize
    let draw: (_ context: CGContext, _ size: CGSize) -> Void
}

let fileManager = FileManager.default
let workspaceRoot = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? fileManager.currentDirectoryPath)
let assetCatalogURL = workspaceRoot
    .appendingPathComponent("PetLife")
    .appendingPathComponent("Assets.xcassets", isDirectory: true)

func makeDirectory(_ url: URL) throws {
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
}

func writeText(_ text: String, to url: URL) throws {
    try text.data(using: .utf8)?.write(to: url)
}

func imageSetContents(filenameBase: String) -> String {
    """
    {
      "images" : [
        {
          "filename" : "\(filenameBase).png",
          "idiom" : "universal",
          "scale" : "1x"
        },
        {
          "filename" : "\(filenameBase)@2x.png",
          "idiom" : "universal",
          "scale" : "2x"
        },
        {
          "filename" : "\(filenameBase)@3x.png",
          "idiom" : "universal",
          "scale" : "3x"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
}

func catalogContents() -> String {
    """
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
}

func rgba(_ color: NSColor) -> CGColor {
    color.usingColorSpace(.deviceRGB)!.cgColor
}

func setFill(_ context: CGContext, _ color: NSColor) {
    context.setFillColor(rgba(color))
}

func setStroke(_ context: CGContext, _ color: NSColor, width: CGFloat, lineCap: CGLineCap = .round, lineJoin: CGLineJoin = .round) {
    context.setStrokeColor(rgba(color))
    context.setLineWidth(width)
    context.setLineCap(lineCap)
    context.setLineJoin(lineJoin)
}

func fillRoundedRect(_ context: CGContext, rect: CGRect, radius: CGFloat, color: NSColor) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    setFill(context, color)
    context.addPath(path)
    context.fillPath()
}

func strokeRoundedRect(_ context: CGContext, rect: CGRect, radius: CGFloat, color: NSColor, width: CGFloat) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    setStroke(context, color, width: width)
    context.addPath(path)
    context.strokePath()
}

func fillEllipse(_ context: CGContext, rect: CGRect, color: NSColor) {
    setFill(context, color)
    context.fillEllipse(in: rect)
}

func fillCircle(_ context: CGContext, center: CGPoint, radius: CGFloat, color: NSColor) {
    fillEllipse(
        context,
        rect: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2),
        color: color
    )
}

func fillPolygon(_ context: CGContext, points: [CGPoint], color: NSColor) {
    guard let first = points.first else { return }
    context.beginPath()
    context.move(to: first)
    for point in points.dropFirst() {
        context.addLine(to: point)
    }
    context.closePath()
    setFill(context, color)
    context.fillPath()
}

func strokePolyline(_ context: CGContext, points: [CGPoint], color: NSColor, width: CGFloat) {
    guard let first = points.first else { return }
    context.beginPath()
    context.move(to: first)
    for point in points.dropFirst() {
        context.addLine(to: point)
    }
    setStroke(context, color, width: width)
    context.strokePath()
}

func drawBlob(_ context: CGContext, rect: CGRect, color: NSColor, alpha: CGFloat = 1) {
    let path = CGMutablePath()
    let minX = rect.minX
    let maxX = rect.maxX
    let minY = rect.minY
    let maxY = rect.maxY
    let midX = rect.midX
    let midY = rect.midY

    path.move(to: CGPoint(x: minX + rect.width * 0.18, y: minY + rect.height * 0.24))
    path.addCurve(
        to: CGPoint(x: midX, y: minY),
        control1: CGPoint(x: minX - rect.width * 0.04, y: minY + rect.height * 0.02),
        control2: CGPoint(x: minX + rect.width * 0.34, y: minY - rect.height * 0.06)
    )
    path.addCurve(
        to: CGPoint(x: maxX - rect.width * 0.08, y: minY + rect.height * 0.26),
        control1: CGPoint(x: maxX - rect.width * 0.12, y: minY - rect.height * 0.02),
        control2: CGPoint(x: maxX + rect.width * 0.02, y: minY + rect.height * 0.08)
    )
    path.addCurve(
        to: CGPoint(x: maxX - rect.width * 0.12, y: maxY - rect.height * 0.10),
        control1: CGPoint(x: maxX + rect.width * 0.02, y: midY),
        control2: CGPoint(x: maxX - rect.width * 0.02, y: maxY)
    )
    path.addCurve(
        to: CGPoint(x: minX + rect.width * 0.22, y: maxY - rect.height * 0.04),
        control1: CGPoint(x: midX + rect.width * 0.14, y: maxY + rect.height * 0.06),
        control2: CGPoint(x: minX + rect.width * 0.34, y: maxY)
    )
    path.addCurve(
        to: CGPoint(x: minX + rect.width * 0.18, y: minY + rect.height * 0.24),
        control1: CGPoint(x: minX + rect.width * 0.02, y: maxY - rect.height * 0.10),
        control2: CGPoint(x: minX - rect.width * 0.06, y: midY)
    )
    setFill(context, color.withAlphaComponent(alpha))
    context.addPath(path)
    context.fillPath()
}

func drawSpark(_ context: CGContext, center: CGPoint, radius: CGFloat, color: NSColor) {
    fillCircle(context, center: center, radius: radius * 0.30, color: color)
    strokePolyline(
        context,
        points: [CGPoint(x: center.x, y: center.y - radius), CGPoint(x: center.x, y: center.y + radius)],
        color: color,
        width: radius * 0.28
    )
    strokePolyline(
        context,
        points: [CGPoint(x: center.x - radius, y: center.y), CGPoint(x: center.x + radius, y: center.y)],
        color: color,
        width: radius * 0.28
    )
}

func drawDogFace(_ context: CGContext, rect: CGRect, fill: NSColor, accent: NSColor, detail: NSColor) {
    let center = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.06)
    let radius = min(rect.width, rect.height) * 0.32

    fillCircle(context, center: CGPoint(x: center.x - radius * 0.86, y: center.y - radius * 0.20), radius: radius * 0.42, color: accent)
    fillCircle(context, center: CGPoint(x: center.x + radius * 0.86, y: center.y - radius * 0.20), radius: radius * 0.42, color: accent)
    fillCircle(context, center: center, radius: radius, color: fill)
    fillCircle(context, center: CGPoint(x: center.x, y: center.y + radius * 0.28), radius: radius * 0.42, color: Palette.cloud)
    fillCircle(context, center: CGPoint(x: center.x - radius * 0.34, y: center.y - radius * 0.14), radius: radius * 0.09, color: detail)
    fillCircle(context, center: CGPoint(x: center.x + radius * 0.34, y: center.y - radius * 0.14), radius: radius * 0.09, color: detail)
    fillCircle(context, center: CGPoint(x: center.x, y: center.y + radius * 0.22), radius: radius * 0.12, color: detail)
    fillRoundedRect(
        context,
        rect: CGRect(x: center.x - radius * 0.72, y: center.y + radius * 0.88, width: radius * 1.44, height: radius * 0.22),
        radius: radius * 0.11,
        color: accent
    )
}

func drawCatFace(_ context: CGContext, rect: CGRect, fill: NSColor, accent: NSColor, detail: NSColor) {
    let center = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.10)
    let radius = min(rect.width, rect.height) * 0.30

    fillPolygon(
        context,
        points: [
            CGPoint(x: center.x - radius * 0.90, y: center.y - radius * 0.40),
            CGPoint(x: center.x - radius * 0.42, y: center.y - radius * 1.20),
            CGPoint(x: center.x - radius * 0.12, y: center.y - radius * 0.30),
        ],
        color: fill
    )
    fillPolygon(
        context,
        points: [
            CGPoint(x: center.x + radius * 0.12, y: center.y - radius * 0.30),
            CGPoint(x: center.x + radius * 0.42, y: center.y - radius * 1.20),
            CGPoint(x: center.x + radius * 0.90, y: center.y - radius * 0.40),
        ],
        color: fill
    )
    fillCircle(context, center: center, radius: radius, color: fill)
    fillPolygon(
        context,
        points: [
            CGPoint(x: center.x - radius * 0.64, y: center.y - radius * 0.42),
            CGPoint(x: center.x - radius * 0.42, y: center.y - radius * 0.90),
            CGPoint(x: center.x - radius * 0.22, y: center.y - radius * 0.38),
        ],
        color: accent
    )
    fillPolygon(
        context,
        points: [
            CGPoint(x: center.x + radius * 0.22, y: center.y - radius * 0.38),
            CGPoint(x: center.x + radius * 0.42, y: center.y - radius * 0.90),
            CGPoint(x: center.x + radius * 0.64, y: center.y - radius * 0.42),
        ],
        color: accent
    )
    fillCircle(context, center: CGPoint(x: center.x - radius * 0.30, y: center.y - radius * 0.08), radius: radius * 0.08, color: detail)
    fillCircle(context, center: CGPoint(x: center.x + radius * 0.30, y: center.y - radius * 0.08), radius: radius * 0.08, color: detail)
    fillPolygon(
        context,
        points: [
            CGPoint(x: center.x, y: center.y + radius * 0.18),
            CGPoint(x: center.x - radius * 0.10, y: center.y + radius * 0.32),
            CGPoint(x: center.x + radius * 0.10, y: center.y + radius * 0.32),
        ],
        color: accent
    )
    strokePolyline(
        context,
        points: [CGPoint(x: center.x - radius * 0.54, y: center.y + radius * 0.18), CGPoint(x: center.x - radius * 1.08, y: center.y + radius * 0.08)],
        color: detail,
        width: radius * 0.06
    )
    strokePolyline(
        context,
        points: [CGPoint(x: center.x - radius * 0.54, y: center.y + radius * 0.32), CGPoint(x: center.x - radius * 1.06, y: center.y + radius * 0.36)],
        color: detail,
        width: radius * 0.06
    )
    strokePolyline(
        context,
        points: [CGPoint(x: center.x + radius * 0.54, y: center.y + radius * 0.18), CGPoint(x: center.x + radius * 1.08, y: center.y + radius * 0.08)],
        color: detail,
        width: radius * 0.06
    )
    strokePolyline(
        context,
        points: [CGPoint(x: center.x + radius * 0.54, y: center.y + radius * 0.32), CGPoint(x: center.x + radius * 1.06, y: center.y + radius * 0.36)],
        color: detail,
        width: radius * 0.06
    )
}

func drawPawGlyph(_ context: CGContext, rect: CGRect, color: NSColor) {
    let scale = min(rect.width, rect.height)
    let center = CGPoint(x: rect.midX, y: rect.midY + scale * 0.10)
    fillEllipse(context, rect: CGRect(x: center.x - scale * 0.20, y: center.y - scale * 0.05, width: scale * 0.40, height: scale * 0.32), color: color)
    let toes = [
        CGPoint(x: center.x - scale * 0.18, y: center.y - scale * 0.28),
        CGPoint(x: center.x - scale * 0.06, y: center.y - scale * 0.38),
        CGPoint(x: center.x + scale * 0.06, y: center.y - scale * 0.38),
        CGPoint(x: center.x + scale * 0.18, y: center.y - scale * 0.28),
    ]
    for toe in toes {
        fillCircle(context, center: toe, radius: scale * 0.08, color: color)
    }
}

func drawPlayGlyph(_ context: CGContext, rect: CGRect, color: NSColor) {
    fillRoundedRect(context, rect: rect, radius: rect.width * 0.20, color: color)
    fillPolygon(
        context,
        points: [
            CGPoint(x: rect.midX - rect.width * 0.12, y: rect.midY - rect.height * 0.18),
            CGPoint(x: rect.midX - rect.width * 0.12, y: rect.midY + rect.height * 0.18),
            CGPoint(x: rect.midX + rect.width * 0.18, y: rect.midY),
        ],
        color: Palette.cloud
    )
}

func drawHeartGlyph(_ context: CGContext, rect: CGRect, color: NSColor) {
    let center = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.08)
    let scale = min(rect.width, rect.height) * 0.45
    let path = CGMutablePath()
    path.move(to: CGPoint(x: center.x, y: center.y + scale * 0.56))
    path.addCurve(
        to: CGPoint(x: center.x - scale, y: center.y - scale * 0.12),
        control1: CGPoint(x: center.x - scale * 0.36, y: center.y + scale * 0.10),
        control2: CGPoint(x: center.x - scale, y: center.y + scale * 0.10)
    )
    path.addCurve(
        to: CGPoint(x: center.x, y: center.y - scale),
        control1: CGPoint(x: center.x - scale, y: center.y - scale * 0.70),
        control2: CGPoint(x: center.x - scale * 0.24, y: center.y - scale)
    )
    path.addCurve(
        to: CGPoint(x: center.x + scale, y: center.y - scale * 0.12),
        control1: CGPoint(x: center.x + scale * 0.24, y: center.y - scale),
        control2: CGPoint(x: center.x + scale, y: center.y - scale * 0.70)
    )
    path.addCurve(
        to: CGPoint(x: center.x, y: center.y + scale * 0.56),
        control1: CGPoint(x: center.x + scale, y: center.y + scale * 0.10),
        control2: CGPoint(x: center.x + scale * 0.36, y: center.y + scale * 0.10)
    )
    setFill(context, color)
    context.addPath(path)
    context.fillPath()
}

func drawSpeechBubble(_ context: CGContext, rect: CGRect, color: NSColor) {
    fillRoundedRect(context, rect: rect, radius: rect.height * 0.36, color: color)
    fillPolygon(
        context,
        points: [
            CGPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY - rect.height * 0.12),
            CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY + rect.height * 0.16),
            CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY - rect.height * 0.02),
        ],
        color: color
    )
}

func drawPhoneCard(_ context: CGContext, rect: CGRect, tint: NSColor) {
    fillRoundedRect(context, rect: rect, radius: rect.width * 0.20, color: Palette.ink)
    let screen = rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.06)
    fillRoundedRect(context, rect: screen, radius: screen.width * 0.18, color: Palette.cloud)
    fillRoundedRect(
        context,
        rect: CGRect(x: rect.midX - rect.width * 0.16, y: rect.minY + rect.height * 0.06, width: rect.width * 0.32, height: rect.height * 0.03),
        radius: rect.width * 0.02,
        color: Palette.ink.withAlphaComponent(0.14)
    )
    fillRoundedRect(
        context,
        rect: CGRect(x: screen.minX + screen.width * 0.12, y: screen.minY + screen.height * 0.12, width: screen.width * 0.76, height: screen.height * 0.18),
        radius: 18,
        color: tint.withAlphaComponent(0.22)
    )
    fillRoundedRect(
        context,
        rect: CGRect(x: screen.minX + screen.width * 0.16, y: screen.minY + screen.height * 0.38, width: screen.width * 0.52, height: screen.height * 0.08),
        radius: 10,
        color: Palette.ink.withAlphaComponent(0.10)
    )
}

func drawContentCard(_ context: CGContext, rect: CGRect, tint: NSColor, accent: NSColor) {
    fillRoundedRect(context, rect: rect, radius: 28, color: Palette.cloud.withAlphaComponent(0.96))
    strokeRoundedRect(context, rect: rect, radius: 28, color: Palette.ink.withAlphaComponent(0.08), width: 1.5)
    fillRoundedRect(context, rect: CGRect(x: rect.minX + 18, y: rect.minY + 18, width: rect.width - 36, height: 16), radius: 8, color: tint.withAlphaComponent(0.20))
    fillRoundedRect(context, rect: CGRect(x: rect.minX + 18, y: rect.minY + 46, width: rect.width * 0.52, height: 12), radius: 6, color: Palette.ink.withAlphaComponent(0.10))
    fillRoundedRect(context, rect: CGRect(x: rect.minX + 18, y: rect.minY + 66, width: rect.width * 0.34, height: 12), radius: 6, color: Palette.ink.withAlphaComponent(0.07))
    drawSpark(context, center: CGPoint(x: rect.maxX - 24, y: rect.minY + 26), radius: 8, color: accent)
}

func drawFeatureIcon(_ context: CGContext, size: CGSize, accent: NSColor, drawInner: (CGContext, CGRect) -> Void) {
    let rect = CGRect(origin: .zero, size: size)
    drawBlob(context, rect: rect.insetBy(dx: size.width * 0.06, dy: size.height * 0.06), color: accent, alpha: 0.16)
    fillCircle(context, center: CGPoint(x: rect.midX, y: rect.midY), radius: size.width * 0.34, color: accent.withAlphaComponent(0.94))
    drawInner(context, CGRect(x: size.width * 0.18, y: size.height * 0.18, width: size.width * 0.64, height: size.height * 0.64))
}

func drawTabIcon(_ context: CGContext, size: CGSize, drawInner: (CGContext, CGRect) -> Void) {
    drawInner(context, CGRect(x: size.width * 0.06, y: size.height * 0.06, width: size.width * 0.88, height: size.height * 0.88))
}

func renderPNG(size: CGSize, scale: CGFloat, draw: (_ context: CGContext, _ size: CGSize) -> Void) -> Data {
    let pixelWidth = Int(size.width * scale)
    let pixelHeight = Int(size.height * scale)
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
        let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
    else {
        fatalError("Unable to create bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    let context = graphicsContext.cgContext
    context.scaleBy(x: scale, y: scale)
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)
    context.clear(CGRect(origin: .zero, size: size))
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    draw(context, size)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    return data
}

func saveAsset(_ asset: AssetDefinition) throws {
    let imageSetURL = assetCatalogURL.appendingPathComponent("\(asset.name).imageset", isDirectory: true)
    try makeDirectory(imageSetURL)
    try writeText(imageSetContents(filenameBase: asset.name), to: imageSetURL.appendingPathComponent("Contents.json"))

    for scale in [1, 2, 3] {
        let suffix = scale == 1 ? "" : "@\(scale)x"
        let pngURL = imageSetURL.appendingPathComponent("\(asset.name)\(suffix).png")
        let data = renderPNG(size: asset.size, scale: CGFloat(scale), draw: asset.draw)
        try data.write(to: pngURL)
    }
}

let assets: [AssetDefinition] = [
    AssetDefinition(name: "hero-auth", size: CGSize(width: 360, height: 240)) { context, _ in
        drawBlob(context, rect: CGRect(x: 20, y: 24, width: 150, height: 120), color: Palette.sky, alpha: 0.20)
        drawBlob(context, rect: CGRect(x: 176, y: 32, width: 154, height: 122), color: Palette.mint, alpha: 0.18)
        drawPhoneCard(context, rect: CGRect(x: 214, y: 34, width: 96, height: 170), tint: Palette.sky)
        drawDogFace(context, rect: CGRect(x: 72, y: 62, width: 104, height: 104), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        drawCatFace(context, rect: CGRect(x: 138, y: 116, width: 86, height: 86), fill: Palette.cocoa, accent: Palette.peach, detail: Palette.ink)
        drawSpeechBubble(context, rect: CGRect(x: 180, y: 36, width: 62, height: 30), color: Palette.cloud.withAlphaComponent(0.94))
        drawPawGlyph(context, rect: CGRect(x: 192, y: 40, width: 26, height: 24), color: Palette.accent)
    },
    AssetDefinition(name: "hero-home", size: CGSize(width: 360, height: 240)) { context, _ in
        drawBlob(context, rect: CGRect(x: 22, y: 18, width: 150, height: 122), color: Palette.gold, alpha: 0.18)
        drawBlob(context, rect: CGRect(x: 180, y: 28, width: 150, height: 122), color: Palette.sky, alpha: 0.16)
        drawContentCard(context, rect: CGRect(x: 196, y: 30, width: 120, height: 90), tint: Palette.sky, accent: Palette.mint)
        drawContentCard(context, rect: CGRect(x: 220, y: 128, width: 98, height: 72), tint: Palette.mint, accent: Palette.accent)
        drawDogFace(context, rect: CGRect(x: 42, y: 72, width: 128, height: 128), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        drawCatFace(context, rect: CGRect(x: 124, y: 132, width: 84, height: 84), fill: Palette.cocoa, accent: Palette.gold, detail: Palette.ink)
    },
    AssetDefinition(name: "hero-tree", size: CGSize(width: 360, height: 240)) { context, _ in
        drawBlob(context, rect: CGRect(x: 16, y: 22, width: 156, height: 118), color: Palette.cloud, alpha: 0.26)
        drawBlob(context, rect: CGRect(x: 180, y: 32, width: 150, height: 118), color: Palette.gold, alpha: 0.16)
        drawContentCard(context, rect: CGRect(x: 186, y: 44, width: 132, height: 126), tint: Palette.pine, accent: Palette.gold)
        drawPawGlyph(context, rect: CGRect(x: 234, y: 92, width: 38, height: 36), color: Palette.pine)
        drawSpark(context, center: CGPoint(x: 210, y: 70), radius: 10, color: Palette.gold)
        drawSpark(context, center: CGPoint(x: 292, y: 70), radius: 10, color: Palette.accent)
        drawDogFace(context, rect: CGRect(x: 50, y: 84, width: 102, height: 102), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        drawCatFace(context, rect: CGRect(x: 100, y: 138, width: 72, height: 72), fill: Palette.cocoa, accent: Palette.peach, detail: Palette.ink)
    },
    AssetDefinition(name: "hero-video", size: CGSize(width: 360, height: 240)) { context, _ in
        drawBlob(context, rect: CGRect(x: 24, y: 26, width: 154, height: 120), color: Palette.peach, alpha: 0.18)
        drawBlob(context, rect: CGRect(x: 184, y: 24, width: 152, height: 126), color: Palette.accent, alpha: 0.14)
        drawContentCard(context, rect: CGRect(x: 176, y: 44, width: 140, height: 142), tint: Palette.peach, accent: Palette.accent)
        drawPlayGlyph(context, rect: CGRect(x: 214, y: 86, width: 66, height: 52), color: Palette.accent)
        drawDogFace(context, rect: CGRect(x: 56, y: 84, width: 112, height: 112), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        drawCatFace(context, rect: CGRect(x: 108, y: 140, width: 74, height: 74), fill: Palette.cocoa, accent: Palette.gold, detail: Palette.ink)
    },
    AssetDefinition(name: "hero-social", size: CGSize(width: 360, height: 240)) { context, _ in
        drawBlob(context, rect: CGRect(x: 18, y: 28, width: 152, height: 114), color: Palette.plum, alpha: 0.14)
        drawBlob(context, rect: CGRect(x: 186, y: 28, width: 154, height: 114), color: Palette.peach, alpha: 0.20)
        drawSpeechBubble(context, rect: CGRect(x: 46, y: 54, width: 112, height: 76), color: Palette.cloud.withAlphaComponent(0.95))
        drawSpeechBubble(context, rect: CGRect(x: 202, y: 54, width: 112, height: 76), color: Palette.cloud.withAlphaComponent(0.95))
        drawDogFace(context, rect: CGRect(x: 66, y: 64, width: 70, height: 70), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        drawCatFace(context, rect: CGRect(x: 224, y: 64, width: 66, height: 66), fill: Palette.cocoa, accent: Palette.peach, detail: Palette.ink)
        drawHeartGlyph(context, rect: CGRect(x: 154, y: 112, width: 52, height: 48), color: Palette.accent)
        drawDogFace(context, rect: CGRect(x: 92, y: 136, width: 92, height: 92), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        drawCatFace(context, rect: CGRect(x: 186, y: 136, width: 82, height: 82), fill: Palette.cocoa, accent: Palette.gold, detail: Palette.ink)
    },
    AssetDefinition(name: "hero-profile", size: CGSize(width: 320, height: 200)) { context, _ in
        drawBlob(context, rect: CGRect(x: 14, y: 18, width: 136, height: 102), color: Palette.sky, alpha: 0.16)
        drawBlob(context, rect: CGRect(x: 162, y: 22, width: 138, height: 104), color: Palette.mint, alpha: 0.16)
        drawContentCard(context, rect: CGRect(x: 160, y: 30, width: 126, height: 140), tint: Palette.mint, accent: Palette.accent)
        drawDogFace(context, rect: CGRect(x: 178, y: 52, width: 54, height: 54), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        drawCatFace(context, rect: CGRect(x: 222, y: 58, width: 44, height: 44), fill: Palette.cocoa, accent: Palette.peach, detail: Palette.ink)
        drawDogFace(context, rect: CGRect(x: 50, y: 82, width: 96, height: 96), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        drawCatFace(context, rect: CGRect(x: 102, y: 132, width: 66, height: 66), fill: Palette.cocoa, accent: Palette.gold, detail: Palette.ink)
    },
    AssetDefinition(name: "feature-home", size: CGSize(width: 80, height: 80)) { context, size in
        drawFeatureIcon(context, size: size, accent: Palette.sky) { ctx, rect in
            drawDogFace(ctx, rect: rect, fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
        }
    },
    AssetDefinition(name: "feature-tree", size: CGSize(width: 80, height: 80)) { context, size in
        drawFeatureIcon(context, size: size, accent: Palette.pine) { ctx, rect in
            drawCatFace(ctx, rect: rect, fill: Palette.cocoa, accent: Palette.peach, detail: Palette.cloud)
        }
    },
    AssetDefinition(name: "feature-video", size: CGSize(width: 80, height: 80)) { context, size in
        drawFeatureIcon(context, size: size, accent: Palette.peach) { ctx, rect in
            drawPlayGlyph(ctx, rect: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.12), color: Palette.accent)
        }
    },
    AssetDefinition(name: "feature-social", size: CGSize(width: 80, height: 80)) { context, size in
        drawFeatureIcon(context, size: size, accent: Palette.accent) { ctx, rect in
            drawSpeechBubble(ctx, rect: CGRect(x: rect.minX + 4, y: rect.minY + rect.height * 0.10, width: rect.width - 8, height: rect.height * 0.54), color: Palette.cloud)
            drawDogFace(ctx, rect: CGRect(x: rect.minX + 8, y: rect.minY + 8, width: rect.width * 0.42, height: rect.height * 0.42), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
            drawCatFace(ctx, rect: CGRect(x: rect.midX, y: rect.minY + 10, width: rect.width * 0.36, height: rect.height * 0.36), fill: Palette.cocoa, accent: Palette.peach, detail: Palette.ink)
        }
    },
    AssetDefinition(name: "feature-profile", size: CGSize(width: 80, height: 80)) { context, size in
        drawFeatureIcon(context, size: size, accent: Palette.mint) { ctx, rect in
            drawDogFace(ctx, rect: CGRect(x: rect.minX + 2, y: rect.minY + 8, width: rect.width * 0.56, height: rect.height * 0.56), fill: Palette.sand, accent: Palette.accent, detail: Palette.ink)
            drawCatFace(ctx, rect: CGRect(x: rect.midX - 2, y: rect.minY + 20, width: rect.width * 0.36, height: rect.height * 0.36), fill: Palette.cocoa, accent: Palette.peach, detail: Palette.ink)
        }
    },
    AssetDefinition(name: "tab-home", size: CGSize(width: 32, height: 32)) { context, size in
        drawTabIcon(context, size: size) { ctx, rect in
            drawDogFace(ctx, rect: rect, fill: Palette.ink, accent: Palette.ink, detail: Palette.cloud)
        }
    },
    AssetDefinition(name: "tab-tree", size: CGSize(width: 32, height: 32)) { context, size in
        drawTabIcon(context, size: size) { ctx, rect in
            drawCatFace(ctx, rect: rect, fill: Palette.ink, accent: Palette.ink, detail: Palette.cloud)
        }
    },
    AssetDefinition(name: "tab-video", size: CGSize(width: 32, height: 32)) { context, size in
        drawTabIcon(context, size: size) { ctx, rect in
            drawPlayGlyph(ctx, rect: rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.16), color: Palette.ink)
        }
    },
    AssetDefinition(name: "tab-social", size: CGSize(width: 32, height: 32)) { context, size in
        drawTabIcon(context, size: size) { ctx, rect in
            drawSpeechBubble(ctx, rect: CGRect(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.12, width: rect.width * 0.88, height: rect.height * 0.62), color: Palette.ink)
            drawHeartGlyph(ctx, rect: CGRect(x: rect.midX - rect.width * 0.18, y: rect.midY - rect.height * 0.02, width: rect.width * 0.36, height: rect.height * 0.34), color: Palette.cloud)
        }
    },
    AssetDefinition(name: "tab-profile", size: CGSize(width: 32, height: 32)) { context, size in
        drawTabIcon(context, size: size) { ctx, rect in
            drawDogFace(ctx, rect: CGRect(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.06, width: rect.width * 0.58, height: rect.height * 0.58), fill: Palette.ink, accent: Palette.ink, detail: Palette.cloud)
            drawCatFace(ctx, rect: CGRect(x: rect.midX, y: rect.midY, width: rect.width * 0.34, height: rect.height * 0.34), fill: Palette.ink, accent: Palette.ink, detail: Palette.cloud)
        }
    },
]

do {
    try makeDirectory(assetCatalogURL)
    try writeText(catalogContents(), to: assetCatalogURL.appendingPathComponent("Contents.json"))
    for asset in assets {
        try saveAsset(asset)
    }
    print("Generated \(assets.count) assets at \(assetCatalogURL.path)")
} catch {
    fputs("Asset generation failed: \(error)\n", stderr)
    exit(1)
}
