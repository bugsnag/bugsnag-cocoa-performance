//
//  BugsnagPerformanceRemoteSpanContext.h
//  BugsnagPerformance
//
//  Created by Robert B on 07/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT
@interface BugsnagPerformanceRemoteSpanContext: BugsnagPerformanceSpanContext

+ (nullable instancetype)contextWithTraceParentString:(NSString *)traceParentString;

@end

NS_ASSUME_NONNULL_END
