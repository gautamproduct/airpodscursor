import XCTest
@testable import AirPodsCursorCore

final class MotionGuardTests: XCTestCase {
    private func rates(_ yaw: Double, _ pitch: Double = 0, _ roll: Double = 0) -> AngularRates {
        AngularRates(timestamp: 0, yaw: yaw, pitch: pitch, roll: roll)
    }

    func testNormalHeadMovementIsTrusted() {
        var g = MotionGuard()
        for (i, r) in [20.0, -150, 300, -400, 80].enumerated() {
            XCTAssertFalse(g.observe(rates(r, r / 2), at: Double(i) * 0.04))
        }
        XCTAssertFalse(g.isSettling(at: 1))
    }

    func testAirPodsBeingHandledIsAJoltOnAnyAxis() {
        var yaw = MotionGuard(), pitch = MotionGuard(), roll = MotionGuard()
        XCTAssertTrue(yaw.observe(rates(-900), at: 1))
        XCTAssertTrue(pitch.observe(rates(0, 700), at: 1))
        XCTAssertTrue(roll.observe(rates(0, 0, -1200), at: 1))
    }

    func testStaysUntrustedBrieflyAfterAJolt() {
        var g = MotionGuard()
        g.observe(rates(1000), at: 2)
        XCTAssertTrue(g.isSettling(at: 2.1))
        XCTAssertTrue(g.isSettling(at: 2 + MotionGuard.settleTime - 0.01))
        XCTAssertFalse(g.isSettling(at: 2 + MotionGuard.settleTime + 0.01))
    }

    func testRepeatedJoltsExtendTheWindow() {
        var g = MotionGuard()
        g.observe(rates(1000), at: 0)
        g.observe(rates(1000), at: 0.7)
        XCTAssertTrue(g.isSettling(at: 1.2))
    }

    func testNoRatesAndResetAreHarmless() {
        var g = MotionGuard()
        XCTAssertFalse(g.observe(nil, at: 0))
        g.observe(rates(1000), at: 1)
        g.reset()
        XCTAssertFalse(g.isSettling(at: 1.1))
    }
}
