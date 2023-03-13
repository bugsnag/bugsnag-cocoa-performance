import XCTest
import BugsnagPerformance

class ConfigurationTests: XCTestCase {

    func testValidateShouldPassIfAPIKeyIsValid() throws {
        let config = BugsnagPerformanceConfiguration(apiKey: "0123456789abcdef0123456789abcdef")
        XCTAssertEqual(config.apiKey, "0123456789abcdef0123456789abcdef")
        try! config.validate()
    }
    
    func testValidateShouldThrowAnExceptionIfAPIKeyIsNotValid() throws {
        let config = BugsnagPerformanceConfiguration(apiKey: "FakeKey")
        XCTAssertThrowsError(try config.validate()) { (error) in
            XCTAssertEqual(error.localizedDescription, "Invalid configuration")
            XCTAssertEqual((error as NSError).code, BugsnagPerformanceConfigurationBadApiKey)
        }
    }
}
