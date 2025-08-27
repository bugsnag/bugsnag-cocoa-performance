//
//  BugsnagPerformanceAppStartSpanControl.h
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanControl.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceAppStartSpanControl: NSObject<BugsnagPerformanceSpanControl>
- (void)setType:(NSString *_Nullable)type;
- (void)clearType;
@end

NS_ASSUME_NONNULL_END
