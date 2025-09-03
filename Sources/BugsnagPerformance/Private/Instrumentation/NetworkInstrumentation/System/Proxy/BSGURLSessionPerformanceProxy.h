//
//  BSGURLSessionPerformanceProxy.h
//
//
//  Created by Karl Stenerud on 20.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BSGURLSessionPerformanceProxy sits in between an NSURLSession and NSURLSessionDelegate to also invoke the shared
 * NSURLSessionTaskDelegate (which captures NSURLSessionTaskMetrics to gather performance data).
 */
@interface BSGURLSessionPerformanceProxy : NSProxy<NSURLSessionDelegate>

- (instancetype)initWithSessionDelegate:(nonnull id<NSURLSessionDelegate>)sessionDelegate
                           taskDelegate:(nonnull id<NSURLSessionTaskDelegate>)taskDelegate;

@end

NS_ASSUME_NONNULL_END
