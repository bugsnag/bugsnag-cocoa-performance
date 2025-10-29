//
//  SpanProcessingPipelineStep.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 14/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

typedef bool (^StepWork)(BugsnagPerformanceSpan *span);

namespace bugsnag {

class SpanProcessingPipelineStep {
public:
    SpanProcessingPipelineStep(StepWork work) noexcept
    : work_(work) {};
    
    ~SpanProcessingPipelineStep() {}
    
    bool run(BugsnagPerformanceSpan *span) noexcept {
        return work_(span);
    }
    
private:
    StepWork work_{nullptr};
};
}
