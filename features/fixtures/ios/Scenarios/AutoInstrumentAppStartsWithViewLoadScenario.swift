//
//  AutoInstrumentAppStartsWithViewLoadScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 20/02/2025.
//

import BugsnagPerformance

@objcMembers
class AutoInstrumentAppStartsWithViewLoadScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        // This test can generate a variable number of spans depending on the OS version,
        // so use a timed send instead.
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
        bugsnagPerfConfig.samplingProbability = 1.0
    }

    override func run() {
        // Save a startup configuration
        let startupConfig = StartupConfiguration(configFile: nil)
        startupConfig.autoInstrumentAppStarts = true
        startupConfig.autoInstrumentViewControllers = true
        startupConfig.enabledMetrics.cpu = true
        startupConfig.enabledMetrics.memory = true
        startupConfig.scenarioName = String(describing: AutoInstrumentAppStartsWithViewLoadScenario.self)
        startupConfig.endpoint = fixtureConfig.tracesURL

        startupConfig.saveStartupConfig()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    override func customViewController() -> UIViewController? {
        return ViewController()
    }
}
