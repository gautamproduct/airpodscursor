#!/usr/bin/env swift
// Renders the AirPodsCursor icon: Resources/AppIcon.icns and docs/icon.png.
//
// The mark: a white earbud on a graphite tile, with two blue arcs for the turn of
// your head. Original vector artwork (no SF Symbols, which Apple's
// license doesn't allow in app icons).
//
// Usage: swift scripts/make-icon.swift [repo-root]
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
}

func render(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    let ns = NSGraphicsContext(bitmapImageRep: rep)!
    let ctx = ns.cgContext
    let s = CGFloat(pixels)

    // macOS icon grid: 824/1024 tile, centered.
    let inset = s * 100 / 1024
    let tile = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let u = tile.width
    let tilePath = CGPath(roundedRect: tile, cornerWidth: u * 0.225, cornerHeight: u * 0.225, transform: nil)
    /// Unit space (0...1, y down) → pixels.
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: tile.minX + x * u, y: tile.maxY - y * u) }

    // Tile: graphite to black, with a soft drop shadow.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.010), blur: s * 0.028, color: rgb(0x000000, 0.35))
    ctx.addPath(tilePath)
    ctx.setFillColor(rgb(0x0B0B0D))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    ctx.drawLinearGradient(gradient([rgb(0x2C2C30), rgb(0x0B0B0D)]),
                           start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.minY), options: [])
    // A cool glow behind the earbud.
    ctx.drawRadialGradient(gradient([rgb(0x0A84FF, 0.32), rgb(0x0A84FF, 0)]),
                           startCenter: P(0.44, 0.48), startRadius: 0, endCenter: P(0.44, 0.48), endRadius: u * 0.42,
                           options: [])
    ctx.restoreGState()

    // Head-motion arcs, upper right.
    func arc(radius: CGFloat, alpha: CGFloat) {
        let c = P(0.42, 0.40)
        let path = CGMutablePath()
        path.addArc(center: c, radius: radius * u, startAngle: .pi * 0.06, endAngle: .pi * 0.36, clockwise: false)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setLineWidth(u * 0.028)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(rgb(0x0A84FF, alpha))
        ctx.strokePath()
        ctx.restoreGState()
    }
    arc(radius: 0.26, alpha: 0.95)
    arc(radius: 0.335, alpha: 0.42)

    // Draws `shape` (built around the origin, in unit lengths, y down) at `center`, rotated.
    func place(_ center: CGPoint, _ degrees: CGFloat, _ body: () -> Void) {
        ctx.saveGState()
        let c = P(center.x, center.y)
        ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: -degrees * .pi / 180)
        ctx.scaleBy(x: u, y: -u) // unit lengths, y down
        body()
        ctx.restoreGState()
    }

    let white = gradient([rgb(0xFFFFFF), rgb(0xE9EBF0), rgb(0xC9CCD3)])
    let tilt: CGFloat = -28

    // Shadow for the whole earbud.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.02), blur: s * 0.05, color: rgb(0x000000, 0.55))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)

    // Stem: a long rounded capsule, down and to the right.
    place(CGPoint(x: 0.53, y: 0.60), tilt) {
        let stem = CGPath(roundedRect: CGRect(x: -0.052, y: -0.20, width: 0.104, height: 0.40),
                          cornerWidth: 0.052, cornerHeight: 0.052, transform: nil)
        ctx.addPath(stem)
        ctx.clip()
        ctx.drawLinearGradient(white, start: CGPoint(x: -0.06, y: 0), end: CGPoint(x: 0.06, y: 0), options: [])
        // Force-sensor flat, a subtle groove.
        ctx.setFillColor(rgb(0x000000, 0.08))
        ctx.fill(CGRect(x: -0.012, y: -0.02, width: 0.006, height: 0.12))
        // Microphone grille at the end.
        ctx.setFillColor(rgb(0x2A2A2E))
        ctx.fillEllipse(in: CGRect(x: -0.024, y: 0.165, width: 0.048, height: 0.022))
    }

    // Silicone ear tip, upper left, slightly grey.
    place(CGPoint(x: 0.30, y: 0.305), tilt - 40) {
        let tip = CGPath(ellipseIn: CGRect(x: -0.085, y: -0.07, width: 0.17, height: 0.14), transform: nil)
        ctx.addPath(tip)
        ctx.clip()
        ctx.drawRadialGradient(gradient([rgb(0xF4F5F8), rgb(0xD5D8DF), rgb(0xA9ADB6)]),
                               startCenter: CGPoint(x: -0.03, y: -0.03), startRadius: 0,
                               endCenter: CGPoint(x: 0, y: 0), endRadius: 0.11, options: [.drawsAfterEndLocation])
    }


    // Head: the rounded body that sits in the ear.
    place(CGPoint(x: 0.42, y: 0.39), tilt) {
        let head = CGPath(ellipseIn: CGRect(x: -0.17, y: -0.135, width: 0.34, height: 0.27), transform: nil)
        ctx.addPath(head)
        ctx.clip()
        ctx.drawRadialGradient(white, startCenter: CGPoint(x: -0.06, y: -0.06), startRadius: 0,
                               endCenter: CGPoint(x: 0, y: 0), endRadius: 0.2, options: [.drawsAfterEndLocation])
        // Black acoustic mesh.
        ctx.setFillColor(rgb(0x1C1C1E))
        ctx.fillEllipse(in: CGRect(x: 0.045, y: -0.075, width: 0.06, height: 0.034))
    }

    ctx.endTransparencyLayer()
    ctx.restoreGState()

    // Specular highlight on the head.
    place(CGPoint(x: 0.39, y: 0.35), tilt) {
        ctx.setFillColor(rgb(0xFFFFFF, 0.85))
        ctx.fillEllipse(in: CGRect(x: -0.07, y: -0.02, width: 0.07, height: 0.022))
    }

    ns.flushGraphics()
    return rep
}

func write(_ rep: NSBitmapImageRep, to url: URL) throws {
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

for size in [16, 32, 128, 256, 512] {
    try write(render(pixels: size), to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try write(render(pixels: size * 2), to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try write(render(pixels: 512), to: root.appendingPathComponent("docs/icon.png"))

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns and docs/icon.png" : "iconutil failed")
