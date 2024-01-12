//
//  AutoInstrumentNetworkNoParentScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 25.04.23.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkNoParentScenario: Scenario {

    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = true
        config.networkRequestCallback = { (info: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo in
            super.ignoreInternalRequests(info: info)
            let testUrl = info.url
            if (testUrl == nil) {
                return info
            }
            if (self.isMazeRunnerAdministrationURL(url: testUrl!)) {
                info.url = nil
            }
            return info
        }
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        let span = BugsnagPerformance.startSpan(name: "parentSpan")
        span.end();
        query(string: "?status=200")
    }
}
