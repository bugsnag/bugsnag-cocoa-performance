//
//  ViewLoadInstrumentationState.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewLoadInstrumentationState.h"

@implementation ViewLoadInstrumentationState

- (void)dealloc {
    if (self.onDealloc != nil) {
        self.onDealloc(self);
    }
}

@end
