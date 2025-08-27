//
//  SimpleStopLoadingIndicatorViewScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 27/08/2025.
//

import BugsnagPerformance

import UIKit

@objcMembers
class SimpleStopLoadingIndicatorViewScenario: Scenario {
    
    var viewController: SimpleStopLoadingIndicatorViewScenario_ViewController?

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 1
        bugsnagPerfConfig.autoInstrumentViewControllers = true
    }
    
    func finishLoading() {
        viewController?.finishLoading()
    }

    override func run() {
        viewController = SimpleStopLoadingIndicatorViewScenario_ViewController()
        UIApplication.shared.windows[0].rootViewController!.present(
            viewController!, animated: true)
    }
}

class SimpleStopLoadingIndicatorViewScenario_ViewController: UIViewController {
    
    var loadingIndicator: BugsnagPerformanceLoadingIndicatorView?

    override func loadView() {
        self.loadingIndicator = BugsnagPerformanceLoadingIndicatorView()
        view = UIView()
        view.addSubview(loadingIndicator!)
    }
    
    func finishLoading() {
        loadingIndicator?.finishLoading()
    }
}
