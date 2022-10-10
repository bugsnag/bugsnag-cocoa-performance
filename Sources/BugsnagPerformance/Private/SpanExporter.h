//
//  SpanExporter.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "SpanData.h"

#import <memory>
#import <vector>

namespace bugsnag {
class SpanExporter {
public:
    virtual ~SpanExporter() = default;
    
    virtual void exportSpans(std::vector<std::unique_ptr<SpanData>> spans) noexcept = 0;
};
}
