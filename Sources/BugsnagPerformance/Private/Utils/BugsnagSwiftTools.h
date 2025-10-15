//
//  BugsnagSwiftTools.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 12.11.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagSwiftTools : NSObject

/**
 * Get the demangled description of an object's class.
 * Note: object must not be a class, otherwise demangling won't work!
 */
+ (NSString * _Nonnull)demangledClassNameFromInstance:(id _Nonnull)object;

@end

NS_ASSUME_NONNULL_END
