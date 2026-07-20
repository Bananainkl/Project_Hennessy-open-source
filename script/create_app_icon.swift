#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetDirectory = root.appendingPathComponent("Assets/AppIcon", isDirectory: true)
let pngURL = assetDirectory.appendingPathComponent("Hennessy-1024.png")
let iconsetURL = assetDirectory.appendingPathComponent("Hennessy.iconset", isDirectory: true)
let icnsURL = assetDirectory.appendingPathComponent("Hennessy.icns")

try FileManager.default.createDirectory(at: assetDirectory, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.22
    let basePath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.018, dy: size * 0.018), xRadius: radius, yRadius: radius)
    basePath.addClip()

    NSGradient(colors: [
        NSColor(red: 1.00, green: 0.36, blue: 0.50, alpha: 1.0),
        NSColor(red: 0.95, green: 0.20, blue: 0.45, alpha: 1.0),
        NSColor(red: 1.00, green: 0.59, blue: 0.22, alpha: 1.0)
    ])?.draw(in: rect, angle: -34)

    NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.48),
        NSColor.white.withAlphaComponent(0.08),
        NSColor.clear
    ])?.draw(in: NSBezierPath(ovalIn: NSRect(x: -size * 0.18, y: size * 0.46, width: size * 0.95, height: size * 0.72)), angle: 70)

    NSGradient(colors: [
        NSColor(red: 1.0, green: 0.78, blue: 0.32, alpha: 0.44),
        NSColor.clear
    ])?.draw(in: NSBezierPath(ovalIn: NSRect(x: size * 0.40, y: size * 0.37, width: size * 0.82, height: size * 0.72)), angle: 120)

    let innerPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.075, dy: size * 0.075), xRadius: size * 0.17, yRadius: size * 0.17)
    NSColor.white.withAlphaComponent(0.18).setStroke()
    innerPath.lineWidth = max(2, size / 110)
    innerPath.stroke()

    let font = NSFont(name: "Snell Roundhand", size: size * 0.62)
        ?? NSFont(name: "Apple Chancery", size: size * 0.58)
        ?? NSFont.systemFont(ofSize: size * 0.58, weight: .semibold)
    let text = "h" as NSString
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white.withAlphaComponent(0.96),
        .shadow: {
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
            shadow.shadowOffset = NSSize(width: 0, height: -size * 0.014)
            shadow.shadowBlurRadius = size * 0.022
            return shadow
        }()
    ]
    let textSize = text.size(withAttributes: attrs)
    text.draw(
        at: NSPoint(x: (size - textSize.width) * 0.50, y: (size - textSize.height) * 0.54),
        withAttributes: attrs
    )

    let tray = NSBezierPath(roundedRect: NSRect(x: size * 0.34, y: size * 0.20, width: size * 0.32, height: size * 0.055), xRadius: size * 0.030, yRadius: size * 0.030)
    NSColor.white.withAlphaComponent(0.22).setFill()
    tray.fill()

    NSColor(red: 1.0, green: 0.90, blue: 0.62, alpha: 0.92).setFill()
    for (index, heightFactor) in [0.020, 0.040, 0.058, 0.040, 0.020].enumerated() {
        let x = size * (0.41 + CGFloat(index) * 0.045)
        let width = max(4, size / 90)
        let height = size * CGFloat(heightFactor)
        NSBezierPath(
            roundedRect: NSRect(x: x - width / 2, y: size * 0.214 - height / 2, width: width, height: height),
            xRadius: width / 2,
            yRadius: width / 2
        ).fill()
    }

    image.unlockFocus()
    return image
}

func pngData(from image: NSImage, pixels: Int) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

let source = drawIcon(size: 1024)
try pngData(from: source, pixels: 1024).write(to: pngURL)

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for (pixels, name) in sizes {
    try pngData(from: source, pixels: pixels).write(to: iconsetURL.appendingPathComponent(name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

print(pngURL.path)
print(icnsURL.path)
