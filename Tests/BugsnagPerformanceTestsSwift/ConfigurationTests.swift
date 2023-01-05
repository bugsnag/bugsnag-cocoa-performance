import XCTest
import BugsnagPerformance

class ConfigurationTests: XCTestCase {

    func testValidateEmptyAPIKey() throws {
        XCTAssertThrowsError(try BugsnagPerformanceConfiguration(apiKey: "")) { (error) in
            XCTAssertEqual(error.localizedDescription, "Invalid configuration")
            XCTAssertEqual((error as NSError).code, BugsnagPerformanceConfigurationBadApiKey)
        }
    }

    func testValidateValidAPIKey() throws {
        let config = try! BugsnagPerformanceConfiguration(apiKey: "0123456789abcdef0123456789abcdef")
        XCTAssertEqual(config.apiKey, "0123456789abcdef0123456789abcdef")
    }
}
