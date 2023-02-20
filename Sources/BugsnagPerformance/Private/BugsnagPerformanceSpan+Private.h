//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

#import "Span.h"

#import <memory>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpan ()

- (instancetype)initWithSpan:(std::unique_ptr<bugsnag::Span>)span NS_DESIGNATED_INITIALIZER;

@property(nonatomic,readwrite) BOOL isEnded;

@end

NS_ASSUME_NONNULL_END
