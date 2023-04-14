//
//  Configurable.hpp
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 12.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

namespace bugsnag {

class Configurable {
public:
    virtual void configure(BugsnagPerformanceConfiguration *config) noexcept = 0;
    virtual ~Configurable() {}
};

}

@protocol BSGConfigurable

- (void)configure:(BugsnagPerformanceConfiguration *)config;

@end
