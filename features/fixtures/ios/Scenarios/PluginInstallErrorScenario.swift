//
//  PluginInstallErrorScenario.swift
//  Fixture
//
//  Created by Yousif Ahmed on 10/06/2025.
//
import BugsnagPerformance

class InstallErrorPlugin: NSObject, BugsnagPerformancePlugin {

    func install(with context: BugsnagPerformancePluginContext) {
        context.add(onSpanStartCallback: { (span: BugsnagPerformanceSpan) in
            span.setAttribute("buggy_span_start", withValue: true)
        })
        
        context.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) in
            span.setAttribute("buggy_span_end", withValue: true)
            return true
        })

        NSException(name: NSExceptionName("InstallErrorPluginException"),
                    reason: "This plugin is intentionally buggy",
                    userInfo: nil).raise()
    }
    
    func start() {}
}

@objcMembers
class PluginInstallErrorScenario: PluginScenario {
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.add(InstallErrorPlugin())
    }
}
