//
//  ManualNetworkTracePropagationScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 29.04.24.
//

import BugsnagPerformance

@objcMembers
class ManualNetworkTracePropagationScenario: Scenario {

    public var urlSession: URLSession?
    private var urlPaths: [String] = []

    required init(fixtureConfig: FixtureConfig) {
        super.init(fixtureConfig: fixtureConfig)
        self.urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }

    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = false
    }

    func query(url: URL) {
        let task = self.urlSession!.dataTask(with: url) {(data, response, error) in
        }
        task.resume()
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        MyNetworkDelegate.shared.urlSession.dataTask(with: url).resume()
    }

    func setCallSites(callSiteStrs: String) {
        var newSites: [String] = []
        for path in callSiteStrs.split(separator: ",") {
            newSites.append(String(path))
        }
        urlPaths = newSites
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        for path in urlPaths {
            query(string: path)
        }
    }
}

extension ManualNetworkTracePropagationScenario : URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        BugsnagPerformance.reportNetworkRequestSpan(task: task, metrics: metrics)
    }
}
