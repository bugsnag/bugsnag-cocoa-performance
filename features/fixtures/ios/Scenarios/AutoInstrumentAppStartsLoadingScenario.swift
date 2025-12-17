//
//  AutoInstrumentAppStartsLoadingScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 30/10/2025.
//

import BugsnagPerformance

@objcMembers
class AutoInstrumentAppStartsLoadingScenario: Scenario {
    
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
        startupConfig.enabledMetrics.rendering = true
        startupConfig.scenarioName = String(describing: AutoInstrumentAppStartsLoadingScenario.self)
        startupConfig.endpoint = fixtureConfig.tracesURL

        startupConfig.saveStartupConfig()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    override func customViewController() -> UIViewController? {
        return AutoInstrumentAppStartsLoadingScenario_ViewController()
    }
}

class AutoInstrumentAppStartsLoadingScenario_ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let loadingIndicator = BugsnagPerformanceLoadingIndicatorView()
        view.addSubview(loadingIndicator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            loadingIndicator.finishLoading()
        }
    }
}
