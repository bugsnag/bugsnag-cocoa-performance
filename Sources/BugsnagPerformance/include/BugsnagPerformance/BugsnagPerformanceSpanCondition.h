//
//  BugsnagPerformanceSpanCondition.h
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 15/01/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

@interface BugsnagPerformanceSpanCondition: NSObject

@property (nonatomic) BOOL isActive;

- (void)closeWithEndTime:(NSDate *)endTime NS_SWIFT_NAME(close(endTime:));
- (BugsnagPerformanceSpanContext *)upgrade;
- (void)cancel;

@end

