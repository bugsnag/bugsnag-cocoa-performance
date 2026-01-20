//
//  ViewLoadInstrumentationState.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

@class ViewLoadInstrumentationState;

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ ViewLoadInstrumentationStateOnDeallocCallback)(ViewLoadInstrumentationState *);

@interface ViewLoadInstrumentationState : NSObject

@property (nonatomic) BOOL isMarkedAsPreloaded;
@property (nonatomic) BOOL hasAppeared;
@property (nonatomic) BOOL isHandlingViewDidAppear;
@property (nonatomic, nullable, weak) UIViewController *viewController;
@property (nonatomic, nullable, weak) UIView *view;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *overallSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *loadViewSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *viewDidLoadSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *viewWillAppearSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *viewAppearingSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *viewDidAppearSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *viewWillLayoutSubviewsSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *subviewLayoutSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *viewDidLayoutSubviewsSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *loadingPhaseSpan;
@property (nonatomic, nullable) ViewLoadInstrumentationStateOnDeallocCallback onDealloc;

@end

NS_ASSUME_NONNULL_END
