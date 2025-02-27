//
//  AutoInstrumentNullNetworkCallbackScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 02.07.24.
//

import Foundation

@objcMembers
class AutoInstrumentNullNetworkCallbackScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true
        bugsnagPerfConfig.networkRequestCallback = nil
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
    }
}
