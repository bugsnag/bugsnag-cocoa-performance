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

    override func configure() {
        super.configure()

        config.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            return true
        })
        config.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            return span.name != "drop_me"
        })
        config.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            self.errorGenerator.throwObjCException()
            return true
        })
        config.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            // Swift is actually auto-compiling in a catch-and-convert-to-NSError
            // whenever a Swift throw crosses the Swift-ObjC membrane. But we do this
            // anyway just in case something changes and this starts to break.
            self.errorGenerator.throwSwiftException()
            return true
        })
        config.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            return span.name != "drop_me_too"
        })
    }

    override func run() {
        BugsnagPerformance.startSpan(name: "MySpan").end()
        BugsnagPerformance.startSpan(name: "drop_me").end()
        BugsnagPerformance.startSpan(name: "drop_me_too").end()
    }
}
