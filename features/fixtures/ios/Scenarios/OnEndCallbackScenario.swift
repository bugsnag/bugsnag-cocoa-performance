//
//  OnEndCallbackScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 25.07.24.
//

import BugsnagPerformance

enum MyError: Error {
    case invalid
}
@objcMembers
class OnEndCallbackScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        
        BugsnagPerformance.startSpan(name: "OnEndCallbackScenarioEarlySpan").end()

        bugsnagPerfConfig.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            return true
        })
        bugsnagPerfConfig.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            return span.name != "drop_me"
        })
        bugsnagPerfConfig.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            self.errorGenerator.throwObjCException()
            return true
        })
        bugsnagPerfConfig.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            // Swift is actually auto-compiling in a catch-and-convert-to-NSError
            // whenever a Swift throw crosses the Swift-ObjC membrane. But we do this
            // anyway just in case something changes and this starts to break.
            self.errorGenerator.throwSwiftException()
            return true
        })
        bugsnagPerfConfig.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            return span.name != "drop_me_too"
        })
        bugsnagPerfConfig.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            Thread.sleep(forTimeInterval: 1.2)
            span.setAttribute("OnSpanEndAttribute", withValue: "OnEndCallbackScenarioValue")
            return true
        })
    }

    override func run() {
        BugsnagPerformance.startSpan(name: "OnEndCallbackScenario").end()
        BugsnagPerformance.startSpan(name: "drop_me").end()
        BugsnagPerformance.startSpan(name: "drop_me_too").end()
        let blockedSpan = BugsnagPerformance.startSpan(name: "OnEndCallbackScenarioBlockedSpan")
        let condition = blockedSpan.block(timeout: 0.7)
        condition?.upgrade()
        blockedSpan.end()
        condition?.close(endTime: Date())
    }
}
