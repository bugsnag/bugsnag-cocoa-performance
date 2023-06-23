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
    
    static let mazeRunnerURL = "http://bs-local.com:9339"
    
    var config = BugsnagPerformanceConfiguration.loadConfig()
    var pendingMeasurements: [MazerunnerMeasurement] = []
    
    func configure() {
        NSLog("Scenario.configure()")

        // Make sure the initial P value has time to be fully received before sending spans
        config.internal.initialRecurringWorkDelay = 0.5

        config.internal.clearPersistenceOnStart = true
        config.internal.autoTriggerExportOnBatchSize = 1
        config.apiKey = "12312312312312312312312312312312"
        config.autoInstrumentAppStarts = false
        config.autoInstrumentNetworkRequests = false
        config.autoInstrumentViewControllers = false
        config.endpoint = URL(string:"\(Scenario.mazeRunnerURL)/traces")!
    }
    
    func clearPersistentData() {
        NSLog("Scenario.clearPersistentData()")
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!)
    }
    
    func startBugsnag() {
        NSLog("Scenario.startBugsnag()")
        performAndReportDuration({
            BugsnagPerformance.start(configuration: config)
        }, measurement: "start")
    }
    
    func run() {
        NSLog("Scenario.run() has not been overridden!")
        fatalError("To be implemented by subclass")
    }
    
    func reportMeasurements() {
        pendingMeasurements.forEach { measurement in
            report(metrics: measurement.metrics, name: measurement.name)
        }
        pendingMeasurements = []
    }

    func waitForCurrentBatch() {
        NSLog("Scenario.waitForCurrentBatch()")
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
        guard let url = URL(string: "\(Scenario.mazeRunnerURL)/metrics") else {
            return
        }
        var request = URLRequest(url: url)
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
