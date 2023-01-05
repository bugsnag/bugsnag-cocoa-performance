//
//  NetworkInstrumentation.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 14.10.22.
//

#import <Foundation/Foundation.h>
#import "../Tracer.h"

@interface BSGURLSessionPerformanceDelegate : NSObject
@end

namespace bugsnag {
class NetworkInstrumentation {
public:
    NetworkInstrumentation(Tracer &tracer, NSURL * _Nonnull baseEndpoint) noexcept;
    void start() noexcept;
    
private:
    BSGURLSessionPerformanceDelegate * _Nonnull delegate_;
    Tracer &tracer_;
};
}
