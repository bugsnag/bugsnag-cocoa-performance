//
//  PluginScenario.swift
//  Fixture
//
//  Created by Yousif Ahmed on 09/06/2025.
//
import BugsnagPerformance

class TestSpanControl: NSObject, BugsnagPerformanceSpanControl {
    
    let span: BugsnagPerformanceSpan
    
    init(span: BugsnagPerformanceSpan) {
        self.span = span
        super.init()
    }
}

class SpanCounterPlugin: NSObject, BugsnagPerformancePlugin, BugsnagPerformanceSpanControlProvider {
    var spanList: [BugsnagPerformanceSpan] = []
    var spanCount = 0
    
    func install(with context: BugsnagPerformancePluginContext) {
        context.add(onSpanStartCallback: { (span: BugsnagPerformanceSpan) in
            self.spanCount += 1
            span.setAttribute("spanCount", withValue: self.spanCount)
            self.spanList.append(span)
        })
        
        context.add(self)
    }
    
    func start() {}
    
    func getSpanControls(with query: BugsnagPerformanceSpanQuery) -> BugsnagPerformanceSpanControl? {
        if (query.resultType == TestSpanControl.self && query.getAttributeWithName("index") != nil) {
            let spanCount = query.getAttributeWithName("index") as? Int
            if (spanCount != nil && spanCount! <= self.spanCount) {
                return TestSpanControl(span: self.spanList[spanCount! - 1])
            }
        }
        
        return nil
    }
}

@objcMembers
class PluginScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.add(SpanCounterPlugin())
    }
    
    override func run() {
        let span1 = BugsnagPerformance.startSpan(name: "Span 1")
        let span2 = BugsnagPerformance.startSpan(name: "Span 2")
        let span3 = BugsnagPerformance.startSpan(name: "Span 3")

        let query = BugsnagPerformanceSpanQuery(resultType: TestSpanControl.self, attributes: ["index": 2])
        let spanControl = BugsnagPerformance.getSpanControls(with: query) as? TestSpanControl
        spanControl?.span.setAttribute("queried", withValue: true)
        
        span1.end()
        span2.end()
        span3.end()
    }
}
