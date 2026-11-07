import Foundation

/// Tells real head movement apart from the AirPods being handled: taken out, put in
/// the case, dropped or turned over in a hand. Those spin the sensor far faster than
/// a head can turn, so for a short while afterwards nothing should move the pointer,
/// click, scroll or count as a gesture.
public struct MotionGuard: Sendable {
    /// Rotation faster than this on any axis (deg/s) isn't a head. A brisk head
    /// shake peaks around 300–400 deg/s.
    public static let joltRate = 650.0
    /// How long after a jolt motion stays untrusted.
    public static let settleTime: TimeInterval = 0.8

    public private(set) var lastJolt: TimeInterval = -.infinity

    public init() {}

    public mutating func reset() { lastJolt = -.infinity }

    /// Feed every set of rates (or nil when there are none yet). Returns true when
    /// this sample was a jolt.
    @discardableResult
    public mutating func observe(_ rates: AngularRates?, at time: TimeInterval) -> Bool {
        guard let r = rates else { return false }
        let peak = max(abs(r.yaw), abs(r.pitch), abs(r.roll))
        guard peak >= Self.joltRate else { return false }
        lastJolt = time
        return true
    }

    /// True while motion can't be trusted (just after a jolt).
    public func isSettling(at time: TimeInterval) -> Bool {
        time - lastJolt < Self.settleTime
    }
}
