//
//  AutoInstrumentNetworkPreStartDisabledScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 23.09.24.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkPreStartDisabledScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = false
    }
    
    override func postLoad() {
        super.postLoad()
        query(string: "?status=204")
        
        // Wait for the query to finish before starting bugsnag
        Thread.sleep(forTimeInterval: 2.0)
    }
    
    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }
    
    override func run() {
    }
}
