import Foundation

/// Hands-free reading: rest the pointer near the bottom of the screen and the page
/// scrolls down; rest it near the top and it scrolls up. The deeper into the edge
/// band, the faster it scrolls. Move the pointer back toward the middle to stop.
public struct ReadingScrollSettings: Codable, Equatable, Sendable {
    public var enabled: Bool = true
    /// Height of the top and bottom bands, as a fraction of the usable screen height.
    public var zoneFraction: Double = 0.15
    /// Seconds the pointer must stay in a band before scrolling starts, so passing
    /// through on the way somewhere never scrolls.
    public var delay: Double = 0.4
    /// Overall speed multiplier.
    public var speed: Double = 1.0

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ReadingScrollSettings()
        enabled = c.value(.enabled, default: d.enabled)
        zoneFraction = c.value(.zoneFraction, default: d.zoneFraction)
        delay = c.value(.delay, default: d.delay)
        speed = c.value(.speed, default: d.speed)
    }
}

/// The usable part of a display (menu bar and Dock excluded), in global CG
/// coordinates: origin top-left, +y down.
public struct ScreenArea: Equatable, Sendable {
    public var minX, minY, maxX, maxY: Double

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX; self.minY = minY; self.maxX = maxX; self.maxY = maxY
    }

    public var height: Double { maxY - minY }

    public func contains(_ p: Vec2) -> Bool {
        p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY
    }
}

public struct ReadingScroller: Sendable {
    public var settings: ReadingScrollSettings

    /// Slowest scroll (reading pace) and fastest scroll, in points per second.
    public static let minSpeed = 60.0
    public static let maxSpeed = 900.0

    private var direction = 0
    private var since: TimeInterval?

    public init(settings: ReadingScrollSettings = ReadingScrollSettings()) {
        self.settings = settings
    }

    public mutating func reset() {
        direction = 0
        since = nil
    }

    /// True once the pointer has rested in a band long enough to be scrolling.
    public var isScrolling: Bool { direction != 0 && since == nil }

    /// Scroll velocity in points per second for this frame: positive scrolls the page
    /// down (reveals content below), negative scrolls it up, 0 does nothing.
    public mutating func update(position p: Vec2, area: ScreenArea, time: TimeInterval) -> Double {
        guard settings.enabled, area.height > 0, area.contains(p) else { reset(); return 0 }

        let band = max(1, area.height * min(max(settings.zoneFraction, 0.02), 0.45))
        let dir: Int
        let depth: Double
        if p.y >= area.maxY - band {
            dir = 1
            depth = (p.y - (area.maxY - band)) / band
        } else if p.y <= area.minY + band {
            dir = -1
            depth = ((area.minY + band) - p.y) / band
        } else {
            reset()
            return 0
        }

        if dir != direction {
            direction = dir
            since = time
        }
        if let start = since {
            guard time - start >= settings.delay else { return 0 }
            since = nil
        }

        let d = min(max(depth, 0), 1)
        let speed = (Self.minSpeed + (Self.maxSpeed - Self.minSpeed) * d * d) * max(settings.speed, 0)
        return Double(dir) * speed
    }
}
