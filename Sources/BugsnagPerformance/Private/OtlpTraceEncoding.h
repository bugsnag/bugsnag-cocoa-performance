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
    static NSDictionary * encode(const Span &span) noexcept;
    
    static NSDictionary * encode(std::vector<SpanPtr> spans, NSDictionary *resourceAttributes) noexcept;
    
    static NSArray<NSDictionary *> * encode(NSDictionary *attributes) noexcept;
};
}
