//
//  Gzip.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 20.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Gzip : NSObject

+ (NSData *_Nullable)gzipped:(NSData *)data error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
