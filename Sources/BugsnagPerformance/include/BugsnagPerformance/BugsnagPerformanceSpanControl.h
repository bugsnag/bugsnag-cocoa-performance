//
//  BugsnagPerformanceSpanControl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Marker protocol for classes that can be returned by querying [BugsnagPerformance] or a [BugsnagPerformanceSpanControlProvider]. This interface does
 * not define any specific methods or properties.
 */
@protocol BugsnagPerformanceSpanControl <NSObject>

@end

NS_ASSUME_NONNULL_END
