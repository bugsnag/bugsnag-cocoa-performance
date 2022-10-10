//
//  SpanProcessor.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "SpanData.h"

#import <memory>

namespace bugsnag {
class SpanProcessor {
public:
    virtual ~SpanProcessor() = default;
    
    virtual void onEnd(std::unique_ptr<SpanData> span) noexcept = 0;
};
}
