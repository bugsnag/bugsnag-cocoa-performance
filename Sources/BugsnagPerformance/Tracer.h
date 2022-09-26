//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Span.h"

#import <memory>

class Tracer {
public:
    Tracer(NSURL *endpoint) : endpoint(endpoint) {
        NSLog(@"BugsnagPerformance started");
    }
    
    std::shared_ptr<Span> startSpan(NSString *name, CFAbsoluteTime startTime) {
        return std::make_shared<Span>(name, startTime, ^(const Span &span) {
            this->onEnd(span);
        });
    }
    
    void onEnd(const Span &span);
    
private:
    NSURL *endpoint;
};
