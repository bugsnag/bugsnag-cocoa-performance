//
//  SpanOpenCloseSuite.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 09/09/2025.
//

class SpanOpenCloseSuite: Suite {
    override func run() {
        let options = BugsnagPerformanceSpanOptions()
            .setMakeCurrentContext(false)
            .setFirstClass(.no)
        
        measureRepeated { i in
            BugsnagPerformance
                .startSpan(name: "SpanOpenCloseSuite_\(i)", options: options)
                .end()
        }
    }
}
