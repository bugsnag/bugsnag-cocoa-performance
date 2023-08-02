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

    private override init() {
        super.init()
        self.urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }

    lazy var baseURL: URL = {
        var components = URLComponents(string: Fixture.mazeRunnerURL)!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!
    }()

    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = false
        config.networkRequestCallback = { (info: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo in

            let testUrl = info.url
            if (testUrl == nil) {
                return info
            }

            let url = testUrl!
            let urlString = url.absoluteString

            if (urlString.starts(with:"http://bs-local.com")) {
                info.url = nil
            }
            else if url.absoluteString == "https://google.com" {
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
