//
//  TestHelpers.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 21.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <XCTest/XCTest.h>

// NSLog gets swallowed during unit tests, so work around it using printf.
#define TesterLog(FMT, ...) printf("%s\n", [NSString stringWithFormat:FMT, __VA_ARGS__].UTF8String)
