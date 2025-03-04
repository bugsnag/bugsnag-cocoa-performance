//
//  AutoInstrumentNetworkBadAddressScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 12.05.23.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkBadAddressScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        query(string: "/?status=201")
    }
}
