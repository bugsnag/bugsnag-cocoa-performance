//
//  NamedSpansPluginScenario.swift
//  Fixture
//
//  Created by Yousif Ahmed on 30/07/2025.
//

import BugsnagPerformance
import BugsnagPerformanceNamedSpans

@objcMembers
class NamedSpansPluginScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.add(BugsnagPerformanceNamedSpansPlugin())
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "Test Span")

        let query = BugsnagPerformanceNamedSpanQuery(name: "Test Span")
        
        guard let spanControl = BugsnagPerformance.getSpanControls(with: query) as? BugsnagPerformanceSpan else {
                   return
               }
        
        spanControl.setAttribute("queried", withValue: true)
        spanControl.end()
    }
}

