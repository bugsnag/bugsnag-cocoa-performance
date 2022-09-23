//
//  Span.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <Foundation/Foundation.h>

#import "IdGenerator.h"
#import "SpanKind.h"

class Span {
public:
    Span(NSString *name, CFAbsoluteTime startTime, void (^onEnd)(const Span &span));
    
    void end() {
        endTime = CFAbsoluteTimeGetCurrent();
        onEnd(*this);
    }
    
    NSDictionary * encode() const;
    
private:
    TraceId traceId;
    SpanId spanId;
    NSString *name;
    SpanKind kind;
    CFAbsoluteTime startTime;
    CFAbsoluteTime endTime;
    void (^onEnd)(const Span &span);
};
