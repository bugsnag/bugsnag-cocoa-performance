//
//  ResourceAttributes.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 02/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

namespace bugsnag {
class ResourceAttributes {
public:
    ResourceAttributes(BugsnagPerformanceConfiguration *configuration) noexcept
    : releaseStage_(configuration.releaseStage)
    {}
    
    NSDictionary *get() noexcept;
    
private:
    NSString *releaseStage_;
};
}
