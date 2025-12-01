//
//  Scenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import BugsnagPerformance
import Foundation

typealias MazerunnerMeasurement = (name: String, metrics: [String: Any])

@objcMembers
class Scenario: NSObject {
    let errorGenerator = ErrorGenerator()
    let fixtureConfig: FixtureConfig
    var bugsnagPerfConfig = BugsnagPerformanceConfiguration.loadConfig()
    var pendingMeasurements: [MazerunnerMeasurement] = []
    var scenarioConfig: Dictionary<String,String> = [:]

    private override init() {
        fatalError("do not use the default init of Scenario")
    }

    required init(fixtureConfig: FixtureConfig) {
        self.fixtureConfig = fixtureConfig
    }

    func postLoad() {
        // Called right after loading. Subclasses may need to do things early, before any configuration happens.
    }

    func setInitialBugsnagConfiguration() {
        logDebug("Scenario.setInitialBugsnagConfiguration()")
        bugsnagPerfConfig.internal.clearPersistenceOnStart = true
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 1
        bugsnagPerfConfig.apiKey = "12312312312312312312312312312312"
        bugsnagPerfConfig.autoInstrumentAppStarts = false
        bugsnagPerfConfig.autoInstrumentNetworkRequests = false
        bugsnagPerfConfig.autoInstrumentViewControllers = false
        bugsnagPerfConfig.enabledMetrics.rendering = false
        bugsnagPerfConfig.endpoint = fixtureConfig.tracesURL
        logDebug("Scenario.setInitialBugsnagConfiguration: config.endpoint = \(String(describing: bugsnagPerfConfig.endpoint))")
        bugsnagPerfConfig.networkRequestCallback = filterAdminMazeRunnerNetRequests
    }

    func customViewController() -> UIViewController? {
        // create custom view controller if needed
        return nil
    }

    func saveStartupConfig() {
        let configToSave = StartupConfiguration(configFile: nil)
        configToSave.scenarioName = String(describing: type(of: self))
        configToSave.saveStartupConfig()
    }

    func loadStartupConfig() -> StartupConfiguration {
        let configToLoad = StartupConfiguration(configFile: nil)
        _ = configToLoad.loadStartupConfig()
        return configToLoad
    }

    func applyStartupConfig(startupConfig: StartupConfiguration) {
        bugsnagPerfConfig.autoInstrumentAppStarts = startupConfig.autoInstrumentAppStarts
        bugsnagPerfConfig.autoInstrumentViewControllers = startupConfig.autoInstrumentViewControllers
        bugsnagPerfConfig.apiKey = startupConfig.apiKey
        bugsnagPerfConfig.endpoint = startupConfig.endpoint
        bugsnagPerfConfig.enabledMetrics.rendering = startupConfig.enabledMetrics.rendering
        bugsnagPerfConfig.enabledMetrics.cpu = startupConfig.enabledMetrics.cpu
        bugsnagPerfConfig.enabledMetrics.memory = startupConfig.enabledMetrics.memory
    }

    func urlHasAnyPrefixIn(url: URL, prefixes: [URL]) -> Bool {
        for prefix in prefixes {
            if url.absoluteString.hasPrefix(prefix.absoluteString) {
                return true
            }
        }
        return false
    }

    func filterNetRequestsContainingPrefixes(info: BugsnagPerformanceNetworkRequestInfo,
                                             prefixes: [URL]) -> BugsnagPerformanceNetworkRequestInfo {
        if info.url == nil {
            return info
        }

        if urlHasAnyPrefixIn(url: info.url!, prefixes: prefixes) {
            info.url = nil
        }
        return info
    }

    func filterAllMazeRunnerNetRequests(info: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo {
        return filterNetRequestsContainingPrefixes(info: info, prefixes: fixtureConfig.allMazeRunnerURLs)
    }

    func filterAdminMazeRunnerNetRequests(info: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo {
        // Everything except reflectURL
        return filterNetRequestsContainingPrefixes(info: info, prefixes: fixtureConfig.adminMazeRunnerURLs)
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
        logDebug("Scenario.configureBugsnag(): SET \(path) = \(value)")
        switch path {
        case "propagateTraceParentToUrlsMatching":
            var regexes: Set<NSRegularExpression> = []
            for reStr in splitArgs(args: value) {
                regexes.insert(try! NSRegularExpression(pattern: reStr))
            }
            bugsnagPerfConfig.tracePropagationUrls = regexes
            logDebug("config.tracePropagationUrls = \(regexes)")
            break
        case "cpuMetrics":
            bugsnagPerfConfig.enabledMetrics.cpu = (value == "true")
            logDebug("config.enabledMetrics.cpu = \(bugsnagPerfConfig.enabledMetrics.cpu)")
            break
        case "memoryMetrics":
            bugsnagPerfConfig.enabledMetrics.memory = (value == "true")
            logDebug("config.enabledMetrics.memory = \(bugsnagPerfConfig.enabledMetrics.memory)")
            break
        case "renderingMetrics":
            bugsnagPerfConfig.enabledMetrics.rendering = (value == "true")
            logDebug("config.enabledMetrics.rendering = \(bugsnagPerfConfig.enabledMetrics.rendering)")
            break
        default:
            fatalError("\(path): Unknown configuration path")
        }
    }

    func configureScenario(path: String, value: String) {
        logDebug("Scenario.configureScenario(): Setting \(path) to \(value)")
        scenarioConfig[path] = value;
    }

    func startBugsnag() {
        logDebug("Scenario.startBugsnag()")
        performAndReportDuration({
            logDebug("Scenario.startBugsnag: Trace endpoint = \(String(describing: bugsnagPerfConfig.endpoint))")
            BugsnagPerformance.start(configuration: bugsnagPerfConfig)
        }, measurement: "start")
    }

    func run() {
        logError("Scenario.run() has not been overridden!")
        fatalError("To be implemented by subclass")
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

    func callReflectUrl(appendingToUrl: String) {
        let url = URL(string: appendingToUrl, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    func waitForBrowserstack() {
        // Force sleep so that Browserstack doesn't prematurely shut down
        // the app while BugsnagPerformanceImpl delays for sampling.
        Thread.sleep(forTimeInterval: 2)
    }

    func toDouble(string: String?) -> Double {
        if string == nil {
            return 0
        }
        return Double(string!)!
    }

    func toBool(string: String?) -> Bool {
        return string == "true"
    }

    func toTriState(string: String?) -> BSGTriState {
        switch string {
        case "yes":
            (.yes)
        case "no":
            (.no)
        case "unset":
            (.unset)
        case nil:
            (.unset)
        default:
            fatalError("\(String(describing: string)): Unknown tri-state value")
        }
    }
    
    var spanName: String { "\(String(describing: type(of: self)).replacingOccurrences(of: "Fixture", with: ""))\(scenarioConfig["variant_name"] ?? "")" }
}
