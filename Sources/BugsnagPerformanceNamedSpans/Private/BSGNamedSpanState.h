//
//  BSGNamedSpanState.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 22/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

@interface BSGNamedSpanState : NSObject

@property (nonatomic, strong) BugsnagPerformanceSpan *span;
@property (nonatomic) CFAbsoluteTime expireTime;

@property (nonatomic, strong) BSGNamedSpanState *next;
@property (nonatomic, strong) BSGNamedSpanState *previous;

@end
