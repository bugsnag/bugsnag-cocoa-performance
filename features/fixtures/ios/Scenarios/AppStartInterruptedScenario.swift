//
//  AppStartInterruptedScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 11/12/2025.
//

import BugsnagPerformance

@objcMembers
class AppStartInterruptedScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
        bugsnagPerfConfig.viewControllerInstrumentationCallback = { vc in
            vc is AppStartInterruptedScenario_ViewController
        }
    }

    override func run() {
        // Save a startup configuration
        let startupConfig = StartupConfiguration(configFile: nil)
        startupConfig.autoInstrumentAppStarts = true
        startupConfig.autoInstrumentViewControllers = true
        startupConfig.scenarioName = String(describing: AppStartInterruptedScenario.self)
        startupConfig.endpoint = fixtureConfig.tracesURL

        startupConfig.saveStartupConfig()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    override func customViewController() -> UIViewController? {
        return UINavigationController(rootViewController: AppStartInterruptedScenario_ViewController())
    }
}

class AppStartInterruptedScenario_ViewController: UIViewController {
    
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
        self.navigationController?.pushViewController(UIViewController(), animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadingIndicator?.finishLoading()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                BugsnagPerformance.startSpan(name: "AppStartInterruptedScenario").end()
            }
        }
    }
}
