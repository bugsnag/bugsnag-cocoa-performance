//
//  SpanProcessor.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <memory>

namespace bugsnag {
typedef std::shared_ptr<class Span> SpanPtr;

class SpanProcessor {
public:
    virtual ~SpanProcessor() = default;
    
    virtual void onEnd(SpanPtr span) noexcept = 0;
};
}
