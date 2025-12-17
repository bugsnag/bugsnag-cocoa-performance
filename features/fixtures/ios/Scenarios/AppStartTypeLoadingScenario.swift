//
//  AppStartTypeLoadingScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 10/12/2025.
//

import BugsnagPerformance

@objcMembers
class AppStartTypeLoadingScenario: Scenario {

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
        startupConfig.scenarioName = String(describing: AppStartTypeLoadingScenario.self)
        startupConfig.endpoint = fixtureConfig.tracesURL

        startupConfig.saveStartupConfig()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    override func customViewController() -> UIViewController? {
        return AppStartTypeLoadingScenario_ViewController()
    }
}

class AppStartTypeLoadingScenario_ViewController: UIViewController {
    
    var loadingIndicator: BugsnagPerformanceLoadingIndicatorView?

    required convenience init?(coder: NSCoder) {
        self.init()
    }

    override func loadView() {
        // we are creating a class property because we may have delegates
        // assign your delegates here, before view
        let customView = UIView()
        customView.backgroundColor = .green
        loadingIndicator = BugsnagPerformanceLoadingIndicatorView()
        customView.addSubview(loadingIndicator!)

        view = customView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let query = BugsnagPerformanceAppStartSpanQuery()
            let spanControl = BugsnagPerformance.getSpanControls(with: query) as! BugsnagPerformanceAppStartSpanControl?
            spanControl?.setType("AppStartTypeLoadingScenario")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.loadingIndicator?.finishLoading()
            }
        }
    }
}
