//
//  BugsnagPerformanceSpanControlProvider.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanControl.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanQuery.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BugsnagPerformanceSpanControlProvider <NSObject>

/**
 * Attempt to retrieve the span controls for a given [BugsnagPerformanceSpanQuery]. This is used to access
 * specialised behaviours for specific span types.
 *
 * @param query the span query to retrieve controls for
 * @return the span controls for the given query, or nil if none exists or the query cannot
 *      be fulfilled
 */
- (__nullable id<BugsnagPerformanceSpanControl>)getSpanControlsWithQuery:(BugsnagPerformanceSpanQuery *)query;

@end

NS_ASSUME_NONNULL_END
