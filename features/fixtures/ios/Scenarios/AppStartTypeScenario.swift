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
        logInfo("DARIA_LOG: AppStartTypeScenario_ViewController init")
        super.init(nibName: nil, bundle: nil)

        let query = BugsnagPerformanceAppStartSpanQuery()
        let spanControl = BugsnagPerformance.getSpanControls(with: query) as! BugsnagPerformanceAppStartSpanControl?
        spanControl?.setType("customType")

        logInfo("DARIA_LOG: AppStartTypeScenario_ViewController init done")
    }

    required convenience init?(coder: NSCoder) {
        self.init()
    }

    override func loadView() {
        logInfo("DARIA_LOG: AppStartTypeScenario_ViewController loadView")
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label

        logInfo("DARIA_LOG: AppStartTypeScenario_ViewController loadView done")
    }
}
