//
//  ViewLoadLoadingIndicatorState.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 26/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>

@interface ViewLoadLoadingIndicatorState : NSObject

@property(nonatomic, strong) NSMutableArray<BugsnagPerformanceSpanCondition *> *conditions;
@property(nonatomic, strong) BugsnagPerformanceSpan *loadingIndicatorSpan;
@property(nonatomic) BOOL needsSpanUpdate;

@end
