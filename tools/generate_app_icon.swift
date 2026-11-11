import AppKit
import Foundation

struct IconSlot {
    let idiom: String
    let size: String
    let scale: String
    let filename: String

    var pixelSize: Int {
        let base = Double(size.split(separator: "x").first!) ?? 0
        let scaleValue = Double(scale.replacingOccurrences(of: "x", with: "")) ?? 1
        return Int(base * scaleValue)
    }
}

let slots: [IconSlot] = [
    .init(idiom: "iphone", size: "20x20", scale: "2x", filename: "AppIcon-20@2x.png"),
    .init(idiom: "iphone", size: "20x20", scale: "3x", filename: "AppIcon-20@3x.png"),
    .init(idiom: "iphone", size: "29x29", scale: "2x", filename: "AppIcon-29@2x.png"),
    .init(idiom: "iphone", size: "29x29", scale: "3x", filename: "AppIcon-29@3x.png"),
    .init(idiom: "iphone", size: "40x40", scale: "2x", filename: "AppIcon-40@2x.png"),
    .init(idiom: "iphone", size: "40x40", scale: "3x", filename: "AppIcon-40@3x.png"),
    .init(idiom: "iphone", size: "60x60", scale: "2x", filename: "AppIcon-60@2x.png"),
    .init(idiom: "iphone", size: "60x60", scale: "3x", filename: "AppIcon-60@3x.png"),
    .init(idiom: "ios-marketing", size: "1024x1024", scale: "1x", filename: "AppIcon-1024.png"),
]

let fileManager = FileManager.default
let workspaceRoot = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? fileManager.currentDirectoryPath)
let appIconURL = workspaceRoot
    .appendingPathComponent("PetLife")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset", isDirectory: true)
let referenceImageURL = workspaceRoot
    .appendingPathComponent("tools")
    .appendingPathComponent("app_icon_reference.jpg")

let white = NSColor.white

func makeDirectory(_ url: URL) throws {
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
}

func writeText(_ text: String, to url: URL) throws {
    try text.data(using: .utf8)?.write(to: url)
}

func renderReferenceBitmap(pixelSize: Int) -> NSBitmapImageRep {
    guard let sourceImage = NSImage(contentsOf: referenceImageURL) else {
        fatalError("Unable to load reference image at \(referenceImageURL.path)")
    }

    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
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

    let canvas = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    white.setFill()
    canvas.fill()

    let maxSide = CGFloat(pixelSize) * 0.76
    let sourceSize = sourceImage.size
    let aspect = sourceSize.width / max(sourceSize.height, 1)
    let drawSize: CGSize
    if aspect >= 1 {
        drawSize = CGSize(width: maxSide, height: maxSide / aspect)
    } else {
        drawSize = CGSize(width: maxSide * aspect, height: maxSide)
    }
    let drawRect = CGRect(
        x: (CGFloat(pixelSize) - drawSize.width) / 2,
        y: (CGFloat(pixelSize) - drawSize.height) / 2,
        width: drawSize.width,
        height: drawSize.height
    )

    sourceImage.draw(in: drawRect)
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func renderIcon(pixelSize: Int) -> Data {
    let bitmap = renderReferenceBitmap(pixelSize: pixelSize)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    return data
}

func contentsJSON() -> String {
    let entries = slots.map { slot in
        """
            {
              "filename" : "\(slot.filename)",
              "idiom" : "\(slot.idiom)",
              "scale" : "\(slot.scale)",
              "size" : "\(slot.size)"
            }
        """
    }.joined(separator: ",\n")

    return """
    {
      "images" : [
    \(entries)
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
}

do {
    try makeDirectory(appIconURL)
    try writeText(contentsJSON(), to: appIconURL.appendingPathComponent("Contents.json"))
    for slot in slots {
        let data = renderIcon(pixelSize: slot.pixelSize)
        try data.write(to: appIconURL.appendingPathComponent(slot.filename))
    }
    print("Generated AppIcon at \(appIconURL.path)")
} catch {
    fputs("AppIcon generation failed: \(error)\n", stderr)
    exit(1)
}
