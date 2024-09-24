//
//  FrozenFrameData.mm
//  BugsnagPerformance
//
//  Created by Robert B on 05/09/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FrozenFrameData.h"

@interface FrozenFrameData ()

@property(nonatomic, readwrite) NSTimeInterval startTime;
@property(nonatomic, readwrite) NSTimeInterval endTime;

@end

@implementation FrozenFrameData

+ (FrozenFrameData *)root {
    return [[FrozenFrameData alloc] initWithStartTime:0 endTime:0];
}

- (instancetype)initWithStartTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime {
    if ((self = [super init])) {
        _startTime = startTime;
        _endTime = endTime;
    }
    return self;
}

@end
