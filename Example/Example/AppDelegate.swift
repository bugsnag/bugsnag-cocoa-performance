//
//  AppDelegate.swift
//  Example
//
//  Created by Nick Dowell on 21/09/2022.
//

import BugsnagPerformance
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Spans can be started and ended before starting the SDK. They will be sent once the SDK has started.
        BugsnagPerformance.startSpan(name: "Before start").end()

        let config = BugsnagPerformanceConfiguration.loadConfig()

        // Disable automatic app startup instrumentation:
        //config.autoInstrumentAppStarts = false

        // Disable automatic view controller instrumentation to prevent swizzling...
        //config.autoInstrumentViewControllers = false

        // Disable automatic URLSession request instrumentation:
        //config.autoInstrumentNetworkRequests = false

        // ... or control whether spans are created on a per-instance basis:
        config.viewControllerInstrumentationCallback = {
            !($0 is IgnoredViewController)
        }

        BugsnagPerformance.start(configuration: config)

        return true
    }
}

@available(iOS 13.0, *)
extension AppDelegate {
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
