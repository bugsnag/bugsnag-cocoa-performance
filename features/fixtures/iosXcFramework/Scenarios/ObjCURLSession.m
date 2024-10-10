//
//  ObjCURLSession.m
//  Fixture
//
//  Created by Karl Stenerud on 12.03.24.
//

#import "ObjCURLSession.h"

@implementation ObjCURLSession

+ (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    return [[NSURLSession sharedSession] dataTaskWithURL:url];
}

@end
