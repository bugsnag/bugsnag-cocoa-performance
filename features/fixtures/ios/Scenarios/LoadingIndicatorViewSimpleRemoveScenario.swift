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
        UIApplication.shared.windows[0].rootViewController!.present(
            viewController!, animated: true)
    }
}

class LoadingIndicatorViewSimpleRemoveScenario_ViewController: UIViewController {
    
    var loadingIndicator: BugsnagPerformanceLoadingIndicatorView?

    override func loadView() {
        self.loadingIndicator = BugsnagPerformanceLoadingIndicatorView()
        view = UIView()
        view.addSubview(loadingIndicator!)
    }
    
    func finishLoading() {
        loadingIndicator!.removeFromSuperview()
    }
}
