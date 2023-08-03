//
//  AutoInstrumentNetworkNoParentScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 25.04.23.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkNoParentScenario: Scenario {

    lazy var baseURL: URL = {
        var components = URLComponents(string: Fixture.mazeRunnerURL)!
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
        span.end();
        query(string: "/reflect/?status=200")
    }
}
