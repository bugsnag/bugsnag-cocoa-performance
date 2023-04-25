//
//  AutoInstrumentNetworkNoParentScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 25.04.23.
//

import Foundation

class AutoInstrumentNetworkNoParentScenario: Scenario {

    lazy var baseURL: URL = {
        var components = URLComponents(string: Scenario.mazeRunnerURL)!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!
    }()

    override func startBugsnag() {
        config.autoInstrumentNetworkRequests = true
        super.startBugsnag()
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: baseURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
        waitForCurrentBatch()
        let span = BugsnagPerformance.startSpan(name: "parentSpan")
        span.end();
        query(string: "/reflect/?status=200")
    }
}
