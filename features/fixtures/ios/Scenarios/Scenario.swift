//
//  Scenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import BugsnagPerformance
import Foundation

class Scenario: NSObject {
    
    static let mazeRunnerURL = "http://bs-local.com:9339"
    
    var config = try! BugsnagPerformanceConfiguration.loadConfig()
    
    func configure() {
        bsgp_autoTriggerExportOnBatchSize = 1;
        config.apiKey = "12312312312312312312312312312312"
        config.autoInstrumentAppStarts = false
        config.autoInstrumentNetwork = false
        config.autoInstrumentViewControllers = false
        config.samplingProbability = 1
        config.endpoint = URL(string:"\(Scenario.mazeRunnerURL)/traces")!
    }
    
    func clearPersistentData() {
        NSLog("Scenario.clearPersistentData()")
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!)
    }
    
    func startBugsnag() {
        try! BugsnagPerformance.start(configuration: config)
    }
    
    func run() {
        fatalError("To be implemented by subclass")
    }

    func waitForInitialPResponse() {
        // Guess that it won't take longer than 2 seconds
        Thread.sleep(forTimeInterval: 2.0)
    }

    func waitForCurrentBatch() {
        // Wait long enough to allow the current batch to be packaged and sent
        Thread.sleep(forTimeInterval: 0.5)
    }
}
