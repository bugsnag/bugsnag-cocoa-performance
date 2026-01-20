//
//  LoadingIndicatorViewSimpleRemoveScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 27/08/2025.
//

import BugsnagPerformance

import UIKit

@objcMembers
class LoadingIndicatorViewSimpleRemoveScenario: Scenario {
    
    var viewController: LoadingIndicatorViewSimpleRemoveScenario_ViewController?

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 1
        bugsnagPerfConfig.autoInstrumentViewControllers = true
    }
    
    func finishLoading() {
        viewController?.finishLoading()
    }

    override func run() {
        viewController = LoadingIndicatorViewSimpleRemoveScenario_ViewController()
        viewController?.name = scenarioConfig["name"]
        UIApplication.shared.windows[0].rootViewController!.present(
            viewController!, animated: true)
    }
}

class LoadingIndicatorViewSimpleRemoveScenario_ViewController: UIViewController {
    
    var loadingIndicator: BugsnagPerformanceLoadingIndicatorView?
    var name: String?

    override func loadView() {
        self.loadingIndicator = BugsnagPerformanceLoadingIndicatorView()
        self.loadingIndicator?.name = name
        view = UIView()
        view.addSubview(loadingIndicator!)
    }
    
    func finishLoading() {
        loadingIndicator!.removeFromSuperview()
    }
}
