//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Span.h"

class Tracer {
public:
    Tracer(NSURL *endpoint) : endpoint(endpoint) {
        NSLog(@"BugsnagPerformance started");
    }
    
    Span * startSpan(NSString *name, CFAbsoluteTime startTime) {
        return new Span(name, startTime, ^(const Span &span) {
            this->onEnd(span);
        });
    }
    
    void onEnd(const Span &span);
    
private:
    NSURL *endpoint;
};
