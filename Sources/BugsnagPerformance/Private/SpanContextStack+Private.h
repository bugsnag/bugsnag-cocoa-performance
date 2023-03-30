//
//  SpanContextStack+Private.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 30.03.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "SpanContextStack.h"

@interface SpanContextStack ()

// Accessible for testing only.
@property(nonatomic,readwrite,strong) NSMutableDictionary<NSNumber *, NSPointerArray *> *stacks;

- (void)clearForUnitTests;

@end
