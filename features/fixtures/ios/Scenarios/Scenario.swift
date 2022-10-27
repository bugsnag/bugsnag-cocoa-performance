//
//  Scenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import BugsnagPerformance
import Foundation

class Scenario: NSObject {
    
    static var mazeRunnerURL = URL(string: "http://bs-local.com:9339")!;

    let config: BugsnagPerformanceConfiguration
    
    override init() {
        config = BugsnagPerformanceConfiguration.loadConfig()
        config.autoInstrumentAppStarts = false
        config.autoInstrumentNetwork = false
        config.autoInstrumentViewControllers = false
        config.samplingProbability = 1
        config.endpoint = Scenario.mazeRunnerURL.appendingPathComponent("traces")
    }
    
    func clearPersistentData() {
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!)
    }
    
    func startBugsnag() {
        BugsnagPerformance.start(configuration: config)
    }
    
    func run() {
        fatalError("To be implemented by subclass")
    }
}
