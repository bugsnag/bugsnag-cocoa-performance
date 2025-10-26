//
//  AppLifecycleListener.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

namespace bugsnag {

class AppLifecycleListener {
public:
    virtual void onAppFinishedLaunching() noexcept = 0;
    virtual void onAppEnteredBackground() noexcept = 0;
    virtual void onAppEnteredForeground() noexcept = 0;
    virtual ~AppLifecycleListener() {}
};
}
