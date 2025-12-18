//
//  AppStartTypeEarlyScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 10/12/2025.
//

import BugsnagPerformance

@objcMembers
class AppStartTypeEarlyScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
        let query = BugsnagPerformanceAppStartSpanQuery()
        let spanControl = BugsnagPerformance.getSpanControls(with: query) as! BugsnagPerformanceAppStartSpanControl?
        spanControl?.setType("AppStartTypeEarlyScenario")
    }

    override func run() {
        // Save a startup configuration
        let startupConfig = StartupConfiguration(configFile: nil)
        startupConfig.autoInstrumentAppStarts = true
        startupConfig.autoInstrumentViewControllers = true
        startupConfig.scenarioName = String(describing: AppStartTypeEarlyScenario.self)
        startupConfig.endpoint = fixtureConfig.tracesURL

        startupConfig.saveStartupConfig()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    override func customViewController() -> UIViewController? {
        return AppStartTypeEarlyScenario_ViewController()
    }
}

class AppStartTypeEarlyScenario_ViewController: UIViewController {
    required convenience init?(coder: NSCoder) {
        self.init()
    }

    override func loadView() {
        // we are creating a class property because we may have delegates
        // assign your delegates here, before view
        let customView = UIView()
        customView.backgroundColor = .green

        view = customView
    }
}
