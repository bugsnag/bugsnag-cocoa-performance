//
//  ManualNetworkCallbackScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 24.07.23.
//

import Foundation

@objcMembers
class ManualNetworkCallbackScenario: Scenario {

    public var urlSession: URLSession?

    required init(fixtureConfig: FixtureConfig) {
        super.init(fixtureConfig: fixtureConfig)
        self.urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = false
        bugsnagPerfConfig.networkRequestCallback = { (origInfo: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo in
            let info = self.filterAdminMazeRunnerNetRequests(info: origInfo)

            let testUrl = info.url
            if (testUrl == nil) {
                return info
            }

            let url = testUrl!

            if url.absoluteString == "https://google.com" {
                info.url = nil
            } else if url.lastPathComponent == "changeme" {
                info.url = URL(string:"changed", relativeTo:url.deletingLastPathComponent())
            }

            return info
        }
    }

    func query(url: URL) {
        let task = self.urlSession!.dataTask(with: url) {(data, response, error) in
        }
        task.resume()

    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        query(url: URL(string: "https://bugsnag.com")!)
        query(url: URL(string: "https://bugsnag.com/changeme")!)
        query(url: URL(string: "https://google.com")!)
    }
}

extension ManualNetworkCallbackScenario : URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        BugsnagPerformance.reportNetworkRequestSpan(task: task, metrics: metrics)
    }
}
