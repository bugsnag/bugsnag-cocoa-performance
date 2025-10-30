//
//  Suite.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 09/09/2025.
//

import BugsnagPerformance
import BugsnagPerformanceNamedSpans
import Foundation

class Suite: NSObject {
    let fixtureConfig: FixtureConfig
    var suiteConfig: SuiteConfig?
    var instrumentation: BenchmarkInstrumentation?

    private override init() {
        fatalError("do not use the default init of Scenario")
    }

    required init(fixtureConfig: FixtureConfig) {
        self.fixtureConfig = fixtureConfig
    }

    func startBugsnag(args: [String]) {
        let bugsnagPerfConfig = BugsnagPerformanceConfiguration.loadConfig()
        bugsnagPerfConfig.internal.clearPersistenceOnStart = true
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 50
        bugsnagPerfConfig.apiKey = "12312312312312312312312312312312"
        bugsnagPerfConfig.autoInstrumentAppStarts = false
        bugsnagPerfConfig.autoInstrumentNetworkRequests = false
        bugsnagPerfConfig.autoInstrumentViewControllers = false
        if (args.contains(where: { $0 == "rendering" })) {
            bugsnagPerfConfig.enabledMetrics.rendering = true
        }
        if (args.contains(where: { $0 == "cpu" })) {
            bugsnagPerfConfig.enabledMetrics.cpu = true
        }
        if (args.contains(where: { $0 == "memory" })) {
            bugsnagPerfConfig.enabledMetrics.memory = true
        }
        if (args.contains(where: { $0 == "NamedSpan" })) {
            bugsnagPerfConfig.add(BugsnagPerformanceNamedSpansPlugin())
        }
        bugsnagPerfConfig.endpoint = fixtureConfig.tracesURL
        bugsnagPerfConfig.networkRequestCallback = filterAdminMazeRunnerNetRequests
        bugsnagPerfConfig.releaseStage = "benchmarks"
        bugsnagPerfConfig.enabledReleaseStages = ["release"]
        BugsnagPerformance.start(configuration: bugsnagPerfConfig)
    }
    
    func configure(_ config: SuiteConfig) {
        suiteConfig = config
    }
    
    func instrument(_ instrumentation: BenchmarkInstrumentation) {
        self.instrumentation = instrumentation
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
        logDebug("Sute.clearPersistentData()")
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!)
        let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!
        for file in try! FileManager.default.contentsOfDirectory(at: cachesUrl, includingPropertiesForKeys: nil) {
            try! FileManager.default.removeItem(at: file)
        }
    }

    func run() {
        logError("Suite.run() has not been overridden!")
        fatalError("To be implemented by subclass")
    }
    
    func measureRepeated(_ body: (Int) -> Void) {
        instrumentation?.startMeasuredTime()
        for i in 0..<suiteConfig!.numberOfIterations {
            body(i)
            instrumentation?.recordIteration()
        }
        instrumentation?.endMeasuredTime()
        instrumentation?.startExcludedTime()
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
}
