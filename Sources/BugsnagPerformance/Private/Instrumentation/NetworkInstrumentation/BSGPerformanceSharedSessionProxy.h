//
//  BSGPerformanceSharedSessionProxy.h
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 24/10/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  A proxy for NSURLSession that ignores finishTasksAndInvalidate and invalidateAndCancel calls
 */
@interface BSGPerformanceSharedSessionProxy: NSProxy

- (id)initWithSession:(NSURLSession *)session;

@end

