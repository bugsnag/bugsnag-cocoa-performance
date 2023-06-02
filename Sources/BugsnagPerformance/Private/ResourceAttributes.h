//
//  ResourceAttributes.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 02/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
NS_ASSUME_NONNULL_BEGIN
namespace bugsnag {
class ResourceAttributes {
public:
    ResourceAttributes(BugsnagPerformanceConfiguration *configuration) noexcept
    : releaseStage_(configuration.releaseStage)
    , configuration_(configuration)
    {}
    
    NSDictionary *get() noexcept;
    
private:
    BugsnagPerformanceConfiguration * configuration_;
    NSString *releaseStage_{nil};
};
}
NS_ASSUME_NONNULL_END
