//
//  OnStartCallbackScenario.swift
//  Fixture
//
//  Created by Yousif Ahmed on 22/05/2025.
//

import BugsnagPerformance

@objcMembers
class OnStartCallbackScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()

        bugsnagPerfConfig.add(onSpanStartCallback: { (span: BugsnagPerformanceSpan) in
            span.setAttribute("start_callback_1", withValue: true)
        })

        bugsnagPerfConfig.add(onSpanStartCallback: { (span: BugsnagPerformanceSpan) in
            self.errorGenerator.throwObjCException()
        })

        bugsnagPerfConfig.add(onSpanStartCallback: { (span: BugsnagPerformanceSpan) in
            // Swift is actually auto-compiling in a catch-and-convert-to-NSError
            // whenever a Swift throw crosses the Swift-ObjC membrane. But we do this
            // anyway just in case something changes and this starts to break.
            self.errorGenerator.throwSwiftException()
        })

        bugsnagPerfConfig.add(onSpanStartCallback: { (span: BugsnagPerformanceSpan) in
            span.setAttribute("start_callback_2", withValue: true)
        })
    }

    override func run() {
        BugsnagPerformance.startSpan(name: "OnStartCallbackScenario").end()
    }
}
