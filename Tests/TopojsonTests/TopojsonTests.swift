import XCTest
@testable import Topojson

final class TopojsonTests: XCTestCase {
    var url: URL!

    override func setUp() {
        super.setUp()
        
        let thisSourceFile = URL(fileURLWithPath: #file)
        let thisDirectory = thisSourceFile.deletingLastPathComponent()
        self.url  = thisDirectory.appendingPathComponent("countries.topojson")
    }

    func testLoad() throws {
        _ = try Topojson(self.url)
    }
    
    func testTransform() throws {
        let topo = try Topojson(self.url)
        let updatedArc = topo.transformedArc(arc: 0)
        
        XCTAssertEqual(10, updatedArc.count)
        XCTAssertEqual(-69.9009900990099, updatedArc[0].0)
        XCTAssertEqual(12.451814888520119, updatedArc[0].1)
        
        print("\(updatedArc)")
    }
    
    static var allTests = [
        ("testLoad", testLoad),
        ("testTransform", testTransform),
    ]
}
