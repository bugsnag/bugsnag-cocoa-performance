//
//  AppStartTypeLateScenario.swift
//  Fixture
//
//  Created by Daria Bialobrzeska on 21/10/2025.
//

import BugsnagPerformance

@objcMembers
class AppStartTypeLateScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
    }

    override func run() {
        // Save a startup configuration
        let startupConfig = StartupConfiguration(configFile: nil)
        startupConfig.autoInstrumentAppStarts = true
        startupConfig.autoInstrumentViewControllers = true
        startupConfig.scenarioName = String(describing: AppStartTypeLateScenario.self)
        startupConfig.endpoint = fixtureConfig.tracesURL

        startupConfig.saveStartupConfig()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    override func customViewController() -> UIViewController? {
        return AppStartTypeLateScenario_ViewController()
    }
}

class AppStartTypeLateScenario_ViewController: UIViewController {
    override func loadView() {
        // we are creating a class property because we may have delegates
        // assign your delegates here, before view
        let customView = UIView()
        customView.backgroundColor = .green

        view = customView
    }

    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            let query = BugsnagPerformanceAppStartSpanQuery()
            let spanControl = BugsnagPerformance.getSpanControls(with: query) as! BugsnagPerformanceAppStartSpanControl?
            spanControl?.setType("customType")
        }
    }
}
