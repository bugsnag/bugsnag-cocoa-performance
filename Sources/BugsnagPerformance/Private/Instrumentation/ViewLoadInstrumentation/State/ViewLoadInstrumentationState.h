//
//  ViewLoadInstrumentationState.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

@class ViewLoadInstrumentationState;

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ ViewLoadInstrumentationStateOnDeallocCallback)(ViewLoadInstrumentationState *);

@interface ViewLoadInstrumentationState : NSObject

@property (nonatomic) BOOL loadViewPhaseSpanCreated;
@property (nonatomic) BOOL viewDidLoadPhaseSpanCreated;
@property (nonatomic) BOOL viewWillAppearPhaseSpanCreated;
@property (nonatomic) BOOL viewDidAppearPhaseSpanCreated;
@property (nonatomic) BOOL viewWillLayoutSubviewsPhaseSpanCreated;
@property (nonatomic) BOOL viewDidLayoutSubviewsPhaseSpanCreated;
@property (nonatomic) BOOL isMarkedAsPreloaded;
@property (nonatomic, nullable, strong) NSDate *viewDidLoadEndTime;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *overallSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *viewAppearingSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *subviewLayoutSpan;
@property (nonatomic, nullable) ViewLoadInstrumentationStateOnDeallocCallback onDealloc;

@end

NS_ASSUME_NONNULL_END
