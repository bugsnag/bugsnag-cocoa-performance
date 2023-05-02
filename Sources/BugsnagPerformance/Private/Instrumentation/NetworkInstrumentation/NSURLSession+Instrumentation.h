//
//  NSURLSession+Instrumentation.h
//
//
//  Created by Karl Stenerud on 20.10.22.
//

#ifndef NSURLSession_Instrumentation_h
#define NSURLSession_Instrumentation_h

#import <Foundation/Foundation.h>
#import <memory>
#import "NetworkCommon.h"

/**
 * Performs all swizzling necesary to install tracing for automatic network performance reporting.
 */
void bsg_installNSURLSessionPerformance(id<NSURLSessionTaskDelegate> taskDelegate, BSGIsEnabledCallback isEnbled);

#endif /* NSURLSession_Instrumentation_h */
