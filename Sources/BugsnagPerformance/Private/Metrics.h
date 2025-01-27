//
//  Metrics.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 20.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

namespace bugsnag {

class MetricsOptions {
public:
    MetricsOptions() {}

    MetricsOptions(BugsnagPerformanceSpanMetricsOptions *metrics)
    : rendering(metrics.rendering)
    , cpu(metrics.cpu)
    {}

    BSGTriState rendering{BSGTriStateUnset};
    BSGTriState cpu{BSGTriStateUnset};
};

};
