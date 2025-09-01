//
//  BSGURLSessionPerformanceDelegate.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "../../../Tracer.h"
#import "../State/NetworkInstrumentationStateRepository.h"

NS_ASSUME_NONNULL_BEGIN

@interface BSGURLSessionPerformanceDelegate : NSObject <NSURLSessionTaskDelegate, BSGPhasedStartup>
- (instancetype) initWithTracer:(std::shared_ptr<Tracer>)tracer
         spanAttributesProvider:(std::shared_ptr<SpanAttributesProvider>)spanAttributesProvider
                     repository:(std::shared_ptr<NetworkInstrumentationStateRepository>)repository;
@end

NS_ASSUME_NONNULL_END
