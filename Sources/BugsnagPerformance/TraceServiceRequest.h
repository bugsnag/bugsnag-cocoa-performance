//
//  TraceServiceRequest.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/09/2022.
//

#import "Span.h"

class TraceServiceRequest {
public:
    static NSDictionary * encode(const Span &span);
};
