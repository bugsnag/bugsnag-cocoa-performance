//
//  ViewLoadSpanFactory.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>

#import "../../SpanOptions.h"

@class BugsnagPerformanceSpan;
@class BugsnagPerformanceSpanContext;
@class BugsnagPerformanceSpanCondition;

namespace bugsnag {

class ViewLoadSpanFactory {
public:
    virtual BugsnagPerformanceSpan *startOverallViewLoadSpan(UIViewController *viewController) noexcept = 0;
    virtual BugsnagPerformanceSpan *startPreloadedPresentingSpan(UIViewController *viewController) noexcept = 0;
    virtual BugsnagPerformanceSpan *startLoadViewSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startViewDidLoadSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startViewWillAppearSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startViewAppearingSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startViewDidAppearSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startViewWillLayoutSubviewsSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startSubviewsLayoutSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startViewDidLayoutSubviewsSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startLoadingSpan(UIViewController *viewController,
                                                     BugsnagPerformanceSpanContext *parentContext,
                                                     NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept = 0;
    virtual BugsnagPerformanceSpan *startViewLoadSpan(BugsnagPerformanceViewType viewType,
                                                      NSString *className,
                                                      NSString *suffix,
                                                      const SpanOptions &options,
                                                      NSDictionary *attributes) noexcept = 0;
    virtual BugsnagPerformanceSpan *startViewLoadPhaseSpan(NSString *className,
                                                           BugsnagPerformanceSpanContext *parentContext,
                                                           NSString *phase,
                                                           NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept = 0;
    virtual BugsnagPerformanceSpan *startLoadingIndicatorSpan(NSString *name,
                                                              BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual ~ViewLoadSpanFactory() {}
};
}
