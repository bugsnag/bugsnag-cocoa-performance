//
//  AppStartTypeScenario.swift
//  Fixture
//
//  Created by Daria Bialobrzeska on 02/09/2025.
//

import BugsnagPerformance

@objcMembers
class AppStartTypeScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
        bugsnagPerfConfig.samplingProbability = 1.0
    }

    override func run() {
        // Save a startup configuration
        let startupConfig = StartupConfiguration(configFile: nil)
        startupConfig.autoInstrumentAppStarts = true
        startupConfig.autoInstrumentViewControllers = true
        startupConfig.scenarioName = String(describing: AppStartTypeScenario.self)
        startupConfig.endpoint = fixtureConfig.tracesURL

        startupConfig.saveStartupConfig()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    override func customViewController() -> UIViewController? {
        return AppStartTypeScenario_ViewController()
    }
}

class AppStartTypeScenario_ViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        let query = BugsnagPerformanceAppStartSpanQuery()
        let spanControl = BugsnagPerformance.getSpanControls(with: query) as! BugsnagPerformanceAppStartSpanControl?
        spanControl?.setType("customType")
    }

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
