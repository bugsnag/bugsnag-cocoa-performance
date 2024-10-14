//
//  ObjCURLSession.h
//  Fixture
//
//  Created by Karl Stenerud on 12.03.24.
//

#import <Foundation/Foundation.h>

// Wrapper so that we can pass in nil arguments
@interface ObjCURLSession : NSObject

+ (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url;

@end
