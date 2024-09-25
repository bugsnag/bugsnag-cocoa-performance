//
//  AutoInstrumentNetworkPreStartDisabledScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 23.09.24.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkPreStartDisabledScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = false
    }
    
    override func startBugsnag() {
        query(string: "?status=200")
        
        // Wait for the query to finish before starting bugsnag
        Thread.sleep(forTimeInterval: 2.0)
        
        super.startBugsnag()
    }
    
    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }
    
    override func run() {
    }
}
