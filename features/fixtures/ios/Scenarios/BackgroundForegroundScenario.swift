//
//  BackgroundForegroundScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 10.03.23.
//

import BugsnagPerformance

@objcMembers
class BackgroundForegroundScenario: Scenario {
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    override func configure() {
        super.configure()
        config.internal.autoTriggerExportOnBatchSize = 1
    }
    
    override func run() {
        logError("###### BackgroundForeground START")
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            logError("###### BackgroundForeground ENDING")
            BugsnagPerformance.startSpan(name: "BackgroundForegroundScenario").end()
            logError("###### BackgroundForeground ENDED")
        }
    }
}
