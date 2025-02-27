//
//  AutoInstrumentNetworkSharedSessionInvalidateScenario.swift
//  Fixture
//
//  Created by Robert B on 26/10/2024.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkSharedSessionInvalidateScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true
    }
    
    override func run() {
        URLSession.shared.finishTasksAndInvalidate()
        URLSession.shared.invalidateAndCancel()
        query(string: "?status=200")
    }
    
    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }
}
