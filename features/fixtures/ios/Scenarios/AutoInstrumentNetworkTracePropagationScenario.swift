//
//  AutoInstrumentNetworkTracePropagationScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 30.04.24.
//

import BugsnagPerformance

@objcMembers
class AutoInstrumentNetworkTracePropagationScenario: Scenario {

    private var urlPaths: [String] = []

    required init(fixtureConfig: FixtureConfig) {
        super.init(fixtureConfig: fixtureConfig)
    }

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    func setCallSites(callSiteStrs: String) {
        var newSites: [String] = []
        for path in splitArgs(args: callSiteStrs) {
            newSites.append(String(path))
        }
        urlPaths = newSites
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        for path in urlPaths {
            query(string: path)
        }
    }
}
