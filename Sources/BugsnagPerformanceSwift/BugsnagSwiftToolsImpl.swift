//
//  BugsnagSwiftTools.swift
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 11.11.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

import Foundation

@objc public class BugsnagSwiftToolsImpl: NSObject {
    @objc static public func demangledClassNameFromInstance(object:AnyObject) -> String {
        if let trackedView = object as? BugsnagPerformanceTrackedViewController {
            return trackedView.bugsnagPerformanceTrackedViewName();
        }
        return String(reflecting: type(of: object))
    }
}
