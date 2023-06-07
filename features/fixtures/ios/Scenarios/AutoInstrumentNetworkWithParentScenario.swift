//
//  AutoInstrumentNetworkWithParentScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 20.10.22.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkWithParentScenario: Scenario {

    lazy var baseURL: URL = {
        var components = URLComponents(string: Scenario.mazeRunnerURL)!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!
    }()

    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = true
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: baseURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        let span = BugsnagPerformance.startSpan(name: "parentSpan")
        query(string: "/reflect/?status=200")
        span.end();
    }
}
