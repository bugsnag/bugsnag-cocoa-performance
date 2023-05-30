//
//  AutoInstrumentNetworkBadAddressScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 12.05.23.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkBadAddressScenario: Scenario {

    lazy var baseURL: URL = {
        var components = URLComponents(string: Scenario.mazeRunnerURL)!
        components.port = 9876 // Use the wrong port
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
        query(string: "/reflect/?status=200")
    }
}
