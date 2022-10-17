//
//  NetworkInstrumentation.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 14.10.22.
//

#import <UIKit/UIKit.h>

#import <vector>

namespace bugsnag {
class NetworkInstrumentation {
public:
    NetworkInstrumentation(class Tracer &tracer) noexcept
    : tracer_(tracer)
    {}
    
    void start() noexcept;
    
private:
    class Tracer &tracer_;
};
}
