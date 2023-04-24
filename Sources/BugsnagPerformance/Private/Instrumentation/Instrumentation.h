//
//  Instrumentation.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import "../Configurable.h"
#import "../Startable.h"
#import "../Instrumentation/AppStartupInstrumentation.h"
#import "../Instrumentation/NetworkInstrumentation.h"
#import "../Instrumentation/ViewLoadInstrumentation.h"

namespace bugsnag {

class Instrumentation: public Configurable, public Startable {
public:
    Instrumentation(std::shared_ptr<AppStartupInstrumentation> appStartupInstrumentation, std::shared_ptr<Tracer> tracer) noexcept
    : appStartupInstrumentation_(appStartupInstrumentation)
    , viewLoadInstrumentation_(std::make_shared<ViewLoadInstrumentation>(tracer))
    , networkInstrumentation_(std::make_shared<NetworkInstrumentation>(tracer))
    {}

    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void start() noexcept;
private:
    std::shared_ptr<class AppStartupInstrumentation> appStartupInstrumentation_;
    std::shared_ptr<class ViewLoadInstrumentation> viewLoadInstrumentation_;
    std::shared_ptr<class NetworkInstrumentation> networkInstrumentation_;
};

}
