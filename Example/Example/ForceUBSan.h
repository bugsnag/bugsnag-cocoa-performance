//
//  ForceUBSan.h
//  Example
//
//  Created by Karl Stenerud on 17.03.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// This file exists solely to force the Xcode scheme to allow UBSan to run.
// The UB sanitizer is forcibly disabled if Xcode thinks it's a Swift-only project.
// Linking in a non-swift framework isn't enough to convince it.

@interface ForceUBSan : NSObject

@end

NS_ASSUME_NONNULL_END
