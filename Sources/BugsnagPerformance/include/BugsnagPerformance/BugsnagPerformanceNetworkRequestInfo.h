//
//  BugsnagPerformanceNetworkRequestInfo.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 19.07.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This class is used in network request callbacks to modify network span behaviour on a per-request basis.
 */
@interface BugsnagPerformanceNetworkRequestInfo : NSObject

/**
 * When passed into the callback, this contains the URL of the network request.
 * On return, specifies the URL to report in the network request span.
 * If null on return, no network request span will be created.
 */
@property(readwrite,nonatomic,nullable) NSURL *url;

@end

typedef BugsnagPerformanceNetworkRequestInfo * _Nonnull (^BugsnagPerformanceNetworkRequestCallback)(BugsnagPerformanceNetworkRequestInfo * _Nonnull info);

NS_ASSUME_NONNULL_END
