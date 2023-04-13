//
//  AutoInstrumentNetworkScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 20.10.22.
//

import Foundation

class AutoInstrumentNetworkScenario: Scenario {

    lazy var baseURL: URL = {
        var components = URLComponents(string: Scenario.mazeRunnerURL)!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!
    }()

    override func startBugsnag() {
        config.autoInstrumentNetwork = true
        super.startBugsnag()
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: baseURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
        query(string: "/reflect/?status=200")
        waitForCurrentBatch()
    }
}
