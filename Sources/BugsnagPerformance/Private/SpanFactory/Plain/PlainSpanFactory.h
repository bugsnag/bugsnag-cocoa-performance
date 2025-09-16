//
//  PlainSpanFactory.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 15/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import "../../SpanOptions.h"
#import "../../SpanKind.h"

@class BugsnagPerformanceSpanCondition;

namespace bugsnag {

class PlainSpanFactory {
public:
    virtual BugsnagPerformanceSpan *startSpan(NSString *name,
                                              SpanOptions options,
                                              BSGTriState defaultFirstClass,
                                              NSDictionary *attributes,
                                              NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept = 0;
    virtual BugsnagPerformanceSpan *startSpan(NSString *name,
                                              SpanOptions options,
                                              BSGTriState defaultFirstClass,
                                              SpanKind kind,
                                              NSDictionary *attributes,
                                              NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept = 0;
    virtual ~PlainSpanFactory() {}
};
}
