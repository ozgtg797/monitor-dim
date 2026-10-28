// Renders the app icon: a sun, lit on one side and dimmed on the other.
// Usage: swift Tools/make-icon.swift <out.png>
import AppKit

let size = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha
    )
}

// Body on Apple's 1024 grid: 824pt tile, ~185pt corners.
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGradient(starting: color(0x221E19), ending: color(0x141210))!.draw(in: shape, angle: -90)

// Faint top sheen and inner ring instead of a heavy gradient.
NSGraphicsContext.saveGraphicsState()
shape.addClip()
NSGradient(starting: color(0xFFFFFF, 0.06), ending: color(0xFFFFFF, 0))!
    .draw(in: NSRect(x: 100, y: 512, width: 824, height: 412), angle: -90)
NSGraphicsContext.restoreGraphicsState()
color(0xFFFFFF, 0.07).setStroke()
let ring = NSBezierPath(roundedRect: tile.insetBy(dx: 2, dy: 2), xRadius: 183, yRadius: 183)
ring.lineWidth = 4
ring.stroke()

let lit = color(0xF2C46D)
let dim = color(0x5A4729)
let center = NSPoint(x: 512, y: 512)
let radius: CGFloat = 148
let split: CGFloat = .pi / 4  // the lit/dim boundary runs diagonally, lit side top-left

// Rays fade from lit to dim around the circle.
for i in 0..<8 {
    let angle = CGFloat(i) * .pi / 4 + .pi / 8
    let toLit = (1 + cos(angle - (split + .pi / 2))) / 2  // 1 facing the lit side, 0 opposite
    let ray = NSBezierPath()
    ray.move(to: NSPoint(x: center.x + cos(angle) * (radius + 62), y: center.y + sin(angle) * (radius + 62)))
    ray.line(to: NSPoint(x: center.x + cos(angle) * (radius + 132), y: center.y + sin(angle) * (radius + 132)))
    ray.lineWidth = 36
    ray.lineCapStyle = .round
    dim.blended(withFraction: toLit, of: lit)!.setStroke()
    ray.stroke()
}

let disc = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
dim.setFill()
disc.fill()

NSGraphicsContext.saveGraphicsState()
disc.addClip()
let half = NSBezierPath()
let far: CGFloat = 400
half.move(to: NSPoint(x: center.x + cos(split) * far, y: center.y + sin(split) * far))
half.line(to: NSPoint(x: center.x + cos(split + .pi / 2) * far * 1.5, y: center.y + sin(split + .pi / 2) * far * 1.5))
half.line(to: NSPoint(x: center.x + cos(split + .pi) * far, y: center.y + sin(split + .pi) * far))
half.close()
lit.setFill()
half.fill()
NSGraphicsContext.restoreGraphicsState()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
