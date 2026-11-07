import XCTest
@testable import AirPodsCursorCore

final class ReadingScrollTests: XCTestCase {
    // 1000 pt tall usable area starting at y = 25; bands are 150 pt (15%).
    let area = ScreenArea(minX: 0, minY: 25, maxX: 1440, maxY: 1025)

    func testMiddleOfScreenNeverScrolls() {
        var s = ReadingScroller()
        for i in 0..<100 {
            XCTAssertEqual(s.update(position: Vec2(700, 500), area: area, time: Double(i) * 0.05), 0)
        }
    }

    func testBottomBandScrollsDownAfterDelay() {
        var s = ReadingScroller()
        let p = Vec2(700, 1000)
        XCTAssertEqual(s.update(position: p, area: area, time: 0), 0)
        XCTAssertEqual(s.update(position: p, area: area, time: 0.2), 0, "still inside the delay")
        XCTAssertGreaterThan(s.update(position: p, area: area, time: 0.5), 0)
        XCTAssertTrue(s.isScrolling)
    }

    func testTopBandScrollsUp() {
        var s = ReadingScroller()
        let p = Vec2(700, 60)
        _ = s.update(position: p, area: area, time: 0)
        XCTAssertLessThan(s.update(position: p, area: area, time: 1), 0)
    }

    func testDeeperIsFaster() {
        var shallow = ReadingScroller(), deep = ReadingScroller()
        _ = shallow.update(position: Vec2(700, 880), area: area, time: 0)
        _ = deep.update(position: Vec2(700, 1020), area: area, time: 0)
        let a = shallow.update(position: Vec2(700, 880), area: area, time: 1)
        let b = deep.update(position: Vec2(700, 1020), area: area, time: 1)
        XCTAssertGreaterThan(b, a)
        XCTAssertGreaterThanOrEqual(a, ReadingScroller.minSpeed)
        XCTAssertLessThanOrEqual(b, ReadingScroller.maxSpeed)
    }

    func testPassingThroughDoesNotScroll() {
        var s = ReadingScroller()
        _ = s.update(position: Vec2(700, 1000), area: area, time: 0)
        _ = s.update(position: Vec2(700, 500), area: area, time: 0.3)   // left the band
        XCTAssertEqual(s.update(position: Vec2(700, 1000), area: area, time: 0.5), 0, "delay restarts")
        XCTAssertFalse(s.isScrolling)
    }

    func testSwitchingBandsRestartsDelay() {
        var s = ReadingScroller()
        _ = s.update(position: Vec2(700, 1000), area: area, time: 0)
        XCTAssertGreaterThan(s.update(position: Vec2(700, 1000), area: area, time: 1), 0)
        XCTAssertEqual(s.update(position: Vec2(700, 40), area: area, time: 1.01), 0)
    }

    func testDisabledOrOutsideDoesNothing() {
        var settings = ReadingScrollSettings()
        settings.enabled = false
        var off = ReadingScroller(settings: settings)
        _ = off.update(position: Vec2(700, 1000), area: area, time: 0)
        XCTAssertEqual(off.update(position: Vec2(700, 1000), area: area, time: 2), 0)

        var on = ReadingScroller()
        _ = on.update(position: Vec2(700, 1040), area: area, time: 0) // over the Dock
        XCTAssertEqual(on.update(position: Vec2(700, 1040), area: area, time: 2), 0)
    }

    func testSettingsDecodeLeniently() throws {
        let decoded = try JSONDecoder().decode(AppSettings.self, from: Data("{}".utf8))
        XCTAssertEqual(decoded.readingScroll, ReadingScrollSettings())
        let partial = try JSONDecoder().decode(ReadingScrollSettings.self, from: Data(#"{"speed":2}"#.utf8))
        XCTAssertEqual(partial.speed, 2)
        XCTAssertTrue(partial.enabled)
    }
}
