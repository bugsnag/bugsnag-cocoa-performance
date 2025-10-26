//
//  SpanProcessingPipeline.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 14/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#import "SpanProcessingPipelineStep.h"

namespace bugsnag {

class SpanProcessingPipeline {
public:
    virtual void addSpanForProcessing(BugsnagPerformanceSpan *span) noexcept = 0;
    virtual void removeSpan(BugsnagPerformanceSpan *span) noexcept = 0;
    virtual void processPendingSpansIfNeeded() noexcept = 0;
    virtual NSArray<BugsnagPerformanceSpan *> *drainSendableSpans() noexcept = 0;
    
    virtual ~SpanProcessingPipeline() {}
};
}
