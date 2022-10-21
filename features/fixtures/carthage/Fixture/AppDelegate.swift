//
//  AppDelegate.swift
//  Fixture
//
//  Created by Nick Dowell on 21/10/2022.
//

import BugsnagPerformance
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = BugsnagPerformanceConfiguration.loadConfig()
        BugsnagPerformance.start(configuration: config)
        return true
    }
}
