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

    func install(with context: BugsnagPerformancePluginContext) {
        context.add(onSpanStartCallback: { (span: BugsnagPerformanceSpan) in
            self.spanList.append(span)
            span.setAttribute("span_count", withValue: self.spanList.count)
        })
        
        context.add(self)
    }
    
    func start() {
        for span in self.spanList {
            span.setAttribute("plugin_start", withValue: true)
        }
    }
    
    func getSpanControls(with query: BugsnagPerformanceSpanQuery) -> BugsnagPerformanceSpanControl? {
        guard query.resultType == TestSpanControl.self,
              let index = query.getAttributeWithName("index") as? Int,
              index <= self.spanList.count else {
            return nil
        }
        
        return TestSpanControl(span: self.spanList[index - 1])
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            span1.end()
            span2.end()
            span3.end()
        }
    }
}
