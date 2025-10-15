//
//  SpanProcessingPipelineStep.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 14/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

namespace bugsnag {

class SpanProcessingPipelineStep {
public:
    virtual bool run(BugsnagPerformanceSpan *span) noexcept = 0;
    
    virtual ~SpanProcessingPipeline() {}
};
}
