//
//  SpanExporter.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <memory>
#import <vector>

namespace bugsnag {
typedef std::shared_ptr<class Span> SpanPtr;

class SpanExporter {
public:
    virtual ~SpanExporter() = default;
    
    virtual void exportSpans(std::vector<SpanPtr> spans) noexcept = 0;
};
}
