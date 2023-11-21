//
//  Scenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import BugsnagPerformance
import Foundation

typealias MazerunnerMeasurement = (name: String, metrics: [String: Any])

class Scenario: NSObject {
    let fixtureConfig: FixtureConfig
    var config = BugsnagPerformanceConfiguration.loadConfig()
    var pendingMeasurements: [MazerunnerMeasurement] = []
    
    private override init() {
        fatalError("do not use the default init of Scenario")
    }
    
    required init(fixtureConfig: FixtureConfig) {
        self.fixtureConfig = fixtureConfig
    }

    func configure() {
        logDebug("Scenario.configure()")

        // Make sure the initial P value has time to be fully received before sending spans
        config.internal.initialRecurringWorkDelay = 0.5

        config.internal.clearPersistenceOnStart = true
        config.internal.autoTriggerExportOnBatchSize = 1
        config.apiKey = "12312312312312312312312312312312"
        config.autoInstrumentAppStarts = false
        config.autoInstrumentNetworkRequests = false
        config.autoInstrumentViewControllers = false
        config.endpoint = fixtureConfig.tracesURL
    }
    
    func clearPersistentData() {
        logDebug("Scenario.clearPersistentData()")
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!)
    }
    
    func startBugsnag() {
        logDebug("Scenario.startBugsnag()")
        performAndReportDuration({
            BugsnagPerformance.start(configuration: config)
        }, measurement: "start")
    }
    
    func run() {
        logError("Scenario.run() has not been overridden!")
        fatalError("To be implemented by subclass")
    }
    
    func isMazeRunnerAdministrationURL(url: URL) -> Bool {
        switch url {
        case fixtureConfig.tracesURL, fixtureConfig.commandURL, fixtureConfig.metricsURL:
            return true
        case fixtureConfig.reflectURL:
            return false // reflectURL is fair game!
        default:
            return false
        }
    }

    func reportMeasurements() {
        pendingMeasurements.forEach { measurement in
            report(metrics: measurement.metrics, name: measurement.name)
        }
        pendingMeasurements = []
    }

    func waitForCurrentBatch() {
        logDebug("Scenario.waitForCurrentBatch()")
        // Wait long enough to allow the current batch to be packaged and sent
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func performAndReportDuration(_ body: () -> Void, measurement: String) {
        let startDate = Date()
        body()
        let endDate = Date()
        
        let calendar = Calendar.current
        let duration = calendar.dateComponents([.nanosecond], from: startDate, to: endDate)
        let metrics = ["duration.nanos": "\(duration.nanosecond ?? 0)"]
        pendingMeasurements.append((name: measurement, metrics: metrics))
    }
    
    func report(metrics: [String: Any], name: String) {
        var request = URLRequest(url: fixtureConfig.metricsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body = metrics
        body["metric.measurement"] = name
        body["device.manufacturer"] = "Apple"
        body["device.model"] = UIDevice.current.model
        body["os.name"] = UIDevice.current.systemName
        body["os.version"] = UIDevice.current.systemVersion
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        guard let jsonData = jsonData else {
            return
        }
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request).resume()
    }
}
