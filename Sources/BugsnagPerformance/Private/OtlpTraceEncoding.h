//
//  OtlpTraceEncoding.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 27/09/2022.
//

#import <Foundation/Foundation.h>

#import "Span.h"

namespace bugsnag {
class OtlpTraceEncoding {
public:
    static NSDictionary * encode(const SpanData &span) noexcept;
    
    static NSDictionary * encode(const std::vector<std::unique_ptr<SpanData>> &spans, NSDictionary *resourceAttributes) noexcept;
    
    static NSArray<NSDictionary *> * encode(NSDictionary *attributes) noexcept;
};
}
