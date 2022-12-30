//
//  ObjCUtils.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 30.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "ObjCUtils.h"

NSURL * _Nullable nsurlWithString(NSString * _Nonnull str, NSError * __autoreleasing _Nullable * _Nullable error) {
    if (error != nil) {
        *error = nil;
    }
    auto url = [NSURL URLWithString:str];
    if (url == nil && error != nil) {
        *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid URL: \"%@\"", str],
        }];
    }
    return url;
}

