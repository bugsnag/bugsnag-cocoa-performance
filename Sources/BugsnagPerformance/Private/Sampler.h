//
//  Sampler.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/10/2022.
//

#import "IdGenerator.h"

#import <Foundation/Foundation.h>

namespace bugsnag {
class Sampler {
public:
    Sampler(double fallbackProbability) noexcept;
    
    double getProbability() noexcept;
    
    void setFallbackProbability(double value) noexcept {
        fallbackProbability_ = value;
    }
    
    void setProbability(double probability) noexcept;
    
    struct Decision {
        /// Whether this span should be included in data sent to the back-end.
        bool isSampled;
        
        /// The probability used to make this decision.
        double sampledProbability;
    };
    
    Decision shouldSample(TraceId traceId) noexcept;
    
    void setProbabilityFromResponseHeaders(NSDictionary *headers) noexcept;
    
private:
    double fallbackProbability_;
    double probability_;
    CFAbsoluteTime probabilityExpiry_;
};
}
