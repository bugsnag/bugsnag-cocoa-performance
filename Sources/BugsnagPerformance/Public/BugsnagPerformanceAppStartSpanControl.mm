//
//  BugsnagPerformanceAppStartSpanControl.m
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceSpan.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "BugsnagPerformanceAppStartSpanControl.h"
#import "BugsnagPerformanceAppStartSpanControl+Private.h"

static NSString * const AppStartNameAttribute = @"bugsnag.app_start.name";

@interface BugsnagPerformanceAppStartSpanControl()
@property(nonatomic, weak) BugsnagPerformanceSpan *span;
@end

@implementation BugsnagPerformanceAppStartSpanControl

- (instancetype)initWithSpan:(BugsnagPerformanceSpan *)span {
    self = [super init];
    if (self) {
        self.span = span;
    }
    return self;
}

- (void)setType:(NSString *_Nullable)type {
    @synchronized (self) {
        __strong BugsnagPerformanceSpan *span = self.span;
        if (span == nil || !span.isValid) {
            return;
        }

        NSString *typeStr = @"";
        if (type != nil) {
            typeStr = type;
        }

        [span updateName:typeStr];
        [span setAttribute:AppStartNameAttribute withValue:type];
    }
}

- (void)clearType {
    [self setType:nil];
}

@end
