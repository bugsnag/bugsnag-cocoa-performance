//
//  AutoInstrumentAppStartsScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 07/10/2022.
//

class AutoInstrumentAppStartsScenario: Scenario {
    
    override func startBugsnag() {
        config.autoInstrumentAppStarts = true
        clearPersistentData() 
        super.startBugsnag()
    }
    
    override func run() {
    }
}
