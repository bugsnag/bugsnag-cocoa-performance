//
//  BugsnagPerformanceRemoteSpanContext.mm
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 07/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceRemoteSpanContext.h>
#import "../Private/Utils.h"

static const int kTraceParentComponentTraceId = 1;
static const int kTraceParentComponentSpanId = 2;

@implementation BugsnagPerformanceRemoteSpanContext

+ (nullable instancetype)contextWithTraceParentString:(NSString *)traceParentString {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^00-([0-9a-f]{32})-([0-9a-f]{16})-[0-9]{2}$" options:0 error:nil];
    NSRange allStringRange = NSMakeRange(0, [traceParentString length]);
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:traceParentString options:0 range:allStringRange];
    if (!NSEqualRanges(rangeOfFirstMatch, allStringRange)) {
        BSGLogError(@"Could not decode traceparent string %@ because it is not in correct format", traceParentString);
        return nil;
    }
    
    auto components = [traceParentString componentsSeparatedByString:@"-"];
    auto traceIdString = components[kTraceParentComponentTraceId];
    auto traceIdHiString = [traceIdString substringToIndex:16];
    auto traceIdLoString = [traceIdString substringFromIndex:16];
    auto spanIdString = components[kTraceParentComponentSpanId];
    
    uint64_t traceIdHi = 0;
    [[NSScanner scannerWithString:traceIdHiString] scanHexLongLong:&traceIdHi];
    uint64_t traceIdLo = 0;
    [[NSScanner scannerWithString:traceIdLoString] scanHexLongLong:&traceIdLo];
    SpanId spanId = 0;
    [[NSScanner scannerWithString:spanIdString] scanHexLongLong:&spanId];
    return [[BugsnagPerformanceRemoteSpanContext alloc] initWithTraceId:{.hi = traceIdHi, .lo = traceIdLo } spanId:spanId];
}

@end
