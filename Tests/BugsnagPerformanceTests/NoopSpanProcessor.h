//
//  NoopSpanProcessor.h
//  
//
//  Created by Nick Dowell on 05/10/2022.
//

#import "../../Sources/BugsnagPerformance/Private/SpanProcessor.h"

class NoopSpanProcessor : public bugsnag::SpanProcessor {
public:
    void onEnd(bugsnag::SpanPtr span) noexcept override {};
};
