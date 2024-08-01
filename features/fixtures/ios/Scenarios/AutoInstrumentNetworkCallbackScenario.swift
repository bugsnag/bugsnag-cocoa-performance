//
//  AutoInstrumentNetworkCallbackScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 20.07.23.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkCallbackScenario: Scenario {

    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = true
        config.networkRequestCallback = { (origInfo: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo in
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
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
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
