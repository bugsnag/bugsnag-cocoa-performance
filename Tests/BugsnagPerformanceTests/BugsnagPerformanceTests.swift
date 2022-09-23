import XCTest
@testable import BugsnagPerformance

final class BugsnagPerformanceTests: XCTestCase {
    
    func testSpan() {
        XCTAssertNoThrow(BugsnagPerformance.start(
            configuration: BugsnagPerformanceConfiguration.loadConfig()))
        
        BugsnagPerformance.startSpan(name: "Test").end()
    }
}
