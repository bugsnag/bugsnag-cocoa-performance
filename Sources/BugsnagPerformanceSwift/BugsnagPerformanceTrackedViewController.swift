//
//  BugsnagPerformanceTrackedViewController.swift
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 07/12/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

import Foundation
import UIKit
import BugsnagPerformance

public class BugsnagPerformanceTrackedViewController: UIViewController, BugsnagPerformanceTrackedViewContainer {
    
    var trackedViewController: UIViewController?
    var viewName: String = ""
    
    public override func loadView() {
        let view = UIView()
        self.view = view
        // Can't use guard let because this might be compiled on an older compiler
        if trackedViewController != nil {
            let trackedViewController = self.trackedViewController!
            addChild(trackedViewController)
            trackedViewController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(trackedViewController.view)
            NSLayoutConstraint.activate([
                trackedViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                trackedViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                trackedViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                trackedViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            trackedViewController.didMove(toParent: self)
        }
    }
    
    public override var navigationItem: UINavigationItem {
        trackedViewController!.navigationItem
    }
    
    @objc public func bugsnagPerformanceTrackedViewName() -> String {
        viewName
    }
}

public extension UIViewController {
    func bugsnagTraced(_ name: String? = nil) -> UIViewController {
        let viewController = BugsnagPerformanceTrackedViewController()
        viewController.trackedViewController = self
        viewController.viewName = name ?? BugsnagSwiftToolsImpl.demangledClassNameFromInstance(object: self)
        return viewController
    }
}
