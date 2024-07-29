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
    let errorGenerator = ErrorGenerator()
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
        config.internal.clearPersistenceOnStart = true
        config.internal.autoTriggerExportOnBatchSize = 1
        config.apiKey = "12312312312312312312312312312312"
        config.autoInstrumentAppStarts = false
        config.autoInstrumentNetworkRequests = false
        config.autoInstrumentViewControllers = false
        config.endpoint = fixtureConfig.tracesURL
        config.networkRequestCallback = { (info: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo in
            self.ignoreInternalRequests(info: info)

            return info
        }
    }
    
    func ignoreInternalRequests(info: BugsnagPerformanceNetworkRequestInfo) {
        if (info.url == nil) {
            return
        }
        let urlString = info.url!.absoluteString
        if (urlString.hasSuffix("/metrics") || urlString.contains("/command")) {
            info.url = nil
        }
    }
    
    func clearPersistentData() {
        logDebug("Scenario.clearPersistentData()")
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!)
        let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!
        for file in try! FileManager.default.contentsOfDirectory(at: cachesUrl, includingPropertiesForKeys: nil) {
            try! FileManager.default.removeItem(at: file)
        }
    }

    func splitArgs(args: String) -> [String] {
        return args.split(separator: ",").map(String.init)
    }

    func configureBugsnag(path: String, value: String) {
        logDebug("Scenario.configureBugsnag()")
        switch path {
        case "propagateTraceParentToUrlsMatching":
            var regexes: Set<NSRegularExpression> = []
            for reStr in splitArgs(args: value) {
                regexes.insert(try! NSRegularExpression(pattern: reStr))
            }
            config.propagateTraceParentToUrlsMatching = regexes
            break
        default:
            fatalError("\(path): Unknown configuration path")
        }
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
        if url.absoluteString.hasPrefix(fixtureConfig.tracesURL.absoluteString) ||
            url.absoluteString.hasPrefix(fixtureConfig.commandURL.absoluteString) ||
            url.absoluteString.hasPrefix(fixtureConfig.metricsURL.absoluteString) {
            return true
        }

        if url.absoluteString.hasPrefix(fixtureConfig.reflectURL.absoluteString) {
            return false // reflectURL is fair game!
        }

        return false
    }

    func enterBackground(forSeconds seconds: Int) {
#if canImport(UIKit)
        var documentName = "background_forever.html"
        if (seconds >= 0) {
            documentName = "background_for_\(seconds)_sec.html"
        }
        let url = self.fixtureConfig.docsURL.appendingPathComponent(documentName)
        logInfo("Backgrounding the app using \(documentName)")
        UIApplication.shared.open(url, options: [:]) { success in
            logInfo("Opened \(url) \(success ? "successfully" : "unsuccessfully")");
        }
#else
        fatalError("This e2e test requires UIApplication, which is not available on this platform.")
#endif
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
