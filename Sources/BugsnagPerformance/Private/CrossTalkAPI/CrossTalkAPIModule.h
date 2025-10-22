//
//  CrossTalkAPIModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Core/Module.h"
#import "../Core/PhasedStartup.h"
#import "../Core/SpanStack/SpanStackingHandler.h"
#import "../Core/SpanFactory/Plain/PlainSpanFactory.h"
#import "BugsnagPerformanceCrossTalkAPI.h"

namespace bugsnag {
class CrossTalkAPIModule: public Module {
public:
    CrossTalkAPIModule(std::shared_ptr<PlainSpanFactory> spanFactory,
                       std::shared_ptr<SpanStackingHandler> spanStackingHandler)
    : spanFactory_(spanFactory)
    , spanStackingHandler_(spanStackingHandler) {};
    
    ~CrossTalkAPIModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    
    BugsnagPerformanceCrossTalkAPI *getCrossTalkAPI() noexcept { return [BugsnagPerformanceCrossTalkAPI sharedInstance]; }
    
private:
    
    // Dependencies
    std::shared_ptr<PlainSpanFactory> spanFactory_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    
    CrossTalkAPIModule() = delete;
};
}
