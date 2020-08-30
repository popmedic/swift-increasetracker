import XCTest
@testable import IncreaseTracker

final class IncreaseTrackerTests: XCTestCase {
    func testThrowsWhenTotalBiggerThenInput() {
        XCTAssertThrowsError(try IncreaseTracker<UInt8, UInt8>(1))
        XCTAssertThrowsError(try IncreaseTracker<UInt16, UInt16>(1))
        XCTAssertThrowsError(try IncreaseTracker<UInt32, UInt32>())
        XCTAssertThrowsError(try IncreaseTracker<UInt64, UInt64>())
        XCTAssertThrowsError(try IncreaseTracker<UInt, UInt>(1))
        XCTAssertThrowsError(try IncreaseTracker<UInt8, UInt>(1))
    }
    
    func testInc() {
        // test by increamenting with all the factors of 255 (UInt8.max)
        // we do this because it makes the for loops in the inc helper
        // easily find the expected values.
        inc(by: 1)
        inc(by: 3)
        inc(by: 5)
        inc(by: 15)
        inc(by: 17)
        inc(by: 51)
        inc(by: 85)
    }
    
    func testIncByRandoms() {
        do {
            let exp1 = UInt32.random(in: 0..<UInt32.max)
            let tracker = try IncreaseTracker<UInt, UInt32>(exp1)
            XCTAssertEqual(exp1, tracker.offset)
            var upd = UInt32.random(in: exp1..<UInt32.max)
            let exp2 = upd - tracker.offset
            XCTAssertEqual(try tracker.update(upd), UInt(exp2))
            upd = UInt32.random(in: 0..<tracker.offset)
            let exp3 = (UInt(UInt32.max) - UInt(exp1)) + UInt(upd)
            XCTAssertEqual(try tracker.update(upd), UInt(exp3))
        } catch {
            XCTFail()
        }
    }
    
    private func inc(by: UInt8) {
        do {
            let rollingValue = try IncreaseTracker<UInt16, UInt8>()
            var exp: UInt16 = rollingValue.increased
            let n = (UInt16.max/UInt16(UInt8.max))
            let m = UInt8.max/by
            for i in 0..<n {
                for j in 0..<m {
                    exp = (UInt16(i)*(UInt16(m)*UInt16(by))) + UInt16(j*by)
                    XCTAssertNoThrow(try rollingValue.update(j*by))
                    XCTAssertEqual(rollingValue.increased, exp)
                }
            }
            XCTAssertNoThrow(try rollingValue.update(0))
            XCTAssertThrowsError(try rollingValue.update(1),
                                 "total is only \(rollingValue.increased)")
        } catch {
            XCTFail("should not throw error: \(error)")
        }
    }
}
