//
//  ViewLoadInstrumentationSystemUtilsImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "ViewLoadInstrumentationSystemUtils.h"

namespace bugsnag {

class ViewLoadInstrumentationSystemUtilsImpl: public ViewLoadInstrumentationSystemUtils {
public:
    std::vector<const char *> imagesToInstrument() noexcept;
    std::vector<Class> viewControllerSubclasses(const char *image) noexcept;
};
}
