import XCTest
@testable import SapiMeasurementCore

final class MeasurementCoreTests:XCTestCase {
    private func plane(z:Float=2,confidence:UInt8=2)->DepthFrame {
        .init(width:64,height:48,meters:Array(repeating:z,count:64*48),confidence:Array(repeating:confidence,count:64*48),calibration:.init(fx:500,fy:500,cx:320,cy:240,width:640,height:480))
    }
    func testWinterUnits() {
        XCTAssertEqual(MeasurementEngine.winter(lengthCM:150,girthCM:180)!,449.36963426304767,accuracy:0.00001)
        XCTAssertNil(MeasurementEngine.winter(lengthCM:-1,girthCM:180))
        XCTAssertNil(MeasurementEngine.winter(lengthCM:.nan,girthCM:180))
    }
    func testPortraitInverseAndProjection() throws {
        XCTAssertEqual(DepthFrame.portraitToRaw(.init(0.25,0.75)),.init(0.75,0.75))
        let center=try plane().point(at:.init(0.5,0.5))
        XCTAssertEqual(center.x,0,accuracy:0.0001);XCTAssertEqual(center.y,0,accuracy:0.0001)
        XCTAssertEqual(center.z,2,accuracy:0.0001)
        // Raw x displacement 64 pixels, z=2m, fx=500 => 25.6cm.
        XCTAssertEqual(try MeasurementEngine.distance(.init(0.5,0.5),.init(0.5,0.6),in:plane()),25.6,accuracy:0.0001)
    }
    func testConfidenceAndNonfiniteReject() {
        XCTAssertThrowsError(try plane(confidence:0).point(at:.init(0.5,0.5)))
        XCTAssertThrowsError(try plane(z:.nan).point(at:.init(0.5,0.5)))
        XCTAssertThrowsError(try plane().point(at:.init(-0.1,0.5)))
    }
    func testFlatDepthCannotFabricateGirth() {
        XCTAssertThrowsError(try MeasurementEngine.girth(top:.init(0.5,0.3),bottom:.init(0.5,0.7),in:plane()))
    }
    func testBadGirthPreservesLengthAndWithholdsWeight() throws {
        let result=try MeasurementEngine.cattle(shoulder:.init(0.3,0.5),pin:.init(0.7,0.5),top:.init(0.5,0.3),bottom:.init(0.5,0.7),depth:plane())
        XCTAssertGreaterThan(result.lengthCM,0);XCTAssertNil(result.girth);XCTAssertNil(result.weightKG);XCTAssertNotNil(result.warning)
    }
    func testDepthDiscontinuityRejectsBackgroundMixture() {
        var d=plane()
        d.meters[24*64+32]=3
        XCTAssertThrowsError(try d.point(at:.init(0.5,0.5)))
    }
}
