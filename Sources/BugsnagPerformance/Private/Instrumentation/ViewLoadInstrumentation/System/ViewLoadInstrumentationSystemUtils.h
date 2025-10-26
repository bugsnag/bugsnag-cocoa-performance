//
//  ViewLoadInstrumentationSystemUtils.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <objc/runtime.h>
#import <vector>

namespace bugsnag {

class ViewLoadInstrumentationSystemUtils {
public:
    virtual std::vector<const char *> imagesToInstrument() noexcept = 0;
    virtual std::vector<Class> viewControllerSubclasses(const char *image) noexcept = 0;
    virtual ~ViewLoadInstrumentationSystemUtils() {}
};
}
