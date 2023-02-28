//
//  ProbabilityExpiryScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 24.02.23.
//

import BugsnagPerformance

class ProbabilityExpiryScenario: Scenario {
    
    override func startBugsnag() {
        bsgp_probabilityRequestsPauseForSeconds = 0.1
        bsgp_probabilityValueExpiresAfterSeconds = 0.1
        super.startBugsnag()
    }
    
    override func run() {
        // Check that another P value request gets sent when a span is started after
        // the current P value has expired.

        // Give the initial P value time to expire.
        Thread.sleep(forTimeInterval: 0.5)
        
        // Now starting a new span should trigger a new P value request.
        BugsnagPerformance.startSpan(name: "myspan")
    }
}
