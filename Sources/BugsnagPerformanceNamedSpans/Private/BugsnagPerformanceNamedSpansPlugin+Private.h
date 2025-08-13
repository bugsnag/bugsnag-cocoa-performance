//
//  BugsnagPerformanceNamedSpansPlugin+Private.h
//  BugsnagPerformanceNamedSpans
//
//  Created by Yousif Ahmed on 04/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//
#import <BugsnagPerformanceNamedSpans/BugsnagPerformanceNamedSpansPlugin.h>
#import <unordered_map>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceNamedSpansPlugin ()

/**
 * Creates a new plugin instance with a custom timeout interval (for testing purposes).
 */
- (instancetype)initWithTimeoutInterval:(NSTimeInterval)timeoutInterval NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign, readonly) NSTimeInterval timeoutInterval;

@property (nonatomic, assign, readonly) std::shared_ptr<std::unordered_map<void *, dispatch_source_t>> spanTimeoutTimers;

@end

NS_ASSUME_NONNULL_END
