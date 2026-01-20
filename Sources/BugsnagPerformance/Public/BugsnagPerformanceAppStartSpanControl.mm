//
//  BugsnagPerformanceAppStartSpanControl.m
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import "../Private/BugsnagPerformanceSpan+Private.h"
#import <BugsnagPerformance/BugsnagPerformanceAppStartSpanControl.h>
#import "../Private/BugsnagPerformanceAppStartSpanControl+Private.h"

static NSString * const AppStartNameAttribute = @"bugsnag.app_start.name";

@interface BugsnagPerformanceAppStartSpanControl()
@property(nonatomic, weak) BugsnagPerformanceSpan *span;
@property(nonatomic) NSString *spanPreviousName;
@end

@implementation BugsnagPerformanceAppStartSpanControl

- (instancetype)initWithSpan:(BugsnagPerformanceSpan *)span {
    self = [super init];
    if (self) {
        self.span = span;
        self.spanPreviousName = span.name;
    }
    return self;
}

- (void)setType:(NSString *_Nullable)type {
    @synchronized (self) {
        __strong BugsnagPerformanceSpan *span = self.span;
        if (span == nil || !(span.isValid || span.isBlocked)) {
            return;
        }

        [span forceMutate:^{
            if (type == nil) {
                [span updateName:self.spanPreviousName];
            } else {
                NSString *typeStr = type;
                // Original span name should be in format "[AppStart/$platform$type]"
                NSString *newName = [NSString stringWithFormat:@"%@%@", self.spanPreviousName, typeStr];
                [span updateName:newName];
            }
            [span setAttribute:AppStartNameAttribute withValue:type];
        }];
    }
}

- (void)clearType {
    [self setType:nil];
}

@end
