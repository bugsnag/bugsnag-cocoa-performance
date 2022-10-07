//
//  Scenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import BugsnagPerformance
import Foundation

class Scenario: NSObject {
    
    let config: BugsnagPerformanceConfiguration
    
    override init() {
        config = BugsnagPerformanceConfiguration.loadConfig()
        config.autoInstrumentAppStarts = false
        config.endpoint = URL(string: "http://bs-local.com:9339/traces")!
    }
    
    func startBugsnag() {
        BugsnagPerformance.start(configuration: config)
    }
    
    func run() {
        fatalError("To be implemented by subclass")
    }
}
