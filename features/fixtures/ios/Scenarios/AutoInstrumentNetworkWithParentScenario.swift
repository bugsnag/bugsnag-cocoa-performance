//
//  AutoInstrumentNetworkWithParentScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 20.10.22.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkWithParentScenario: Scenario {

    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = true
        config.networkRequestCallback = { (info: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo in
            let testUrl = info.url
            if (testUrl == nil) {
                return info
            }
            if (Fixture.isMazeRunnerAdministrationURL(url: testUrl!)) {
                info.url = nil
            }
            return info
        }
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: URL(string:Fixture.reflectURL))!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        let span = BugsnagPerformance.startSpan(name: "parentSpan")
        query(string: "/?status=200")
        span.end();
    }
}
