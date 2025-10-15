//
//  BugsnagPerformanceUploader.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "OtlpUploader.h"
#import "../../Utils/Utils.h"

using namespace bugsnag;

typedef NS_ENUM(NSInteger, HTTPStatusCode) {
    /// 402 Payment Required: a nonstandard client error status response code that is reserved for future use.
    ///
    /// This status code is returned by ngrok when a tunnel has expired.
    HTTPStatusCodePaymentRequired = 402,

    /// 407 Proxy Authentication Required: the request has not been applied because it lacks valid authentication credentials
    /// for a proxy server that is between the browser and the server that can access the requested resource.
    HTTPStatusCodeProxyAuthenticationRequired = 407,

    /// 408 Request Timeout: the server would like to shut down this unused connection.
    HTTPStatusCodeClientTimeout = 408,

    /// 429 Too Many Requests: the user has sent too many requests in a given amount of time ("rate limiting").
    HTTPStatusCodeTooManyRequests = 429,
};

void OtlpUploader::upload(OtlpPackage &package, UploadResultCallback callback) noexcept {
    BSGLogDebug(@"OtlpUploader::upload(package, callback)");
    auto urlRequest = [NSMutableURLRequest requestWithURL:(NSURL *)endpoint_];
    [urlRequest setValue:apiKey_ forHTTPHeaderField:@"Bugsnag-Api-Key"];

    NSDate *now = [NSDate new];
    NSString *suffix = @"";
    NSISO8601DateFormatOptions options = NSISO8601DateFormatWithInternetDateTime;
    if (@available(iOS 11.2, *)) {
        options |= NSISO8601DateFormatWithFractionalSeconds;
    } else {
        NSDateComponents *components = [NSCalendar.currentCalendar components:(NSCalendarUnitNanosecond) fromDate:now];
        NSInteger msec = components.nanosecond / 1000000;
        suffix = [NSString stringWithFormat:@".%03ldZ", (long)msec];
    }
    NSString *timestamp = [NSISO8601DateFormatter stringFromDate:now
                                                        timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]
                                                   formatOptions:options];
    if (suffix.length > 0) {
        timestamp = [NSString stringWithFormat:@"%@%@", [timestamp substringToIndex:timestamp.length-1], suffix];
    }

    [urlRequest setValue:timestamp forHTTPHeaderField:@"Bugsnag-Sent-At"];
    package.fillURLRequest(urlRequest);

    BSGLogTrace(@"OtlpUploader::upload: Uploading to URL: %@", urlRequest.URL);
    BSGLogTrace(@"OtlpUploader::upload: Uploading HTTP headers: %@", urlRequest.allHTTPHeaderFields);
    BSGLogTrace(@"OtlpUploader::upload: Uploading HTTP body:\n%@", [[NSString alloc] initWithData:(NSData*)urlRequest.HTTPBody encoding:NSUTF8StringEncoding]);

    [[NSURLSession.sharedSession dataTaskWithRequest:urlRequest completionHandler:
      ^(__unused NSData *responseData, NSURLResponse *response, __unused NSError *taskError) {
        if (callback) {
            auto uploadResult = getUploadResult(response);
            BSGLogDebug(@"OtlpUploader::upload: callback(%d)", uploadResult);
            callback(uploadResult);
        }
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            BSGLogTrace(@"OtlpUploader::upload: HTTP response headers = \n%@", ((NSHTTPURLResponse *_Nonnull)response).allHeaderFields);
            BSGLogTrace(@"OtlpUploader::upload: HTTP response data = \n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

        if (newProbabilityCallback_) {
            auto newProbability = getNewProbability(response);
            if (newProbability >= 0 && newProbability <= 1) {
                BSGLogTrace(@"OtlpUploader::upload: newProbabilityCallback_(%f)", newProbability);
                newProbabilityCallback_(newProbability);
            }
        }
    }] resume];
}

UploadResult OtlpUploader::getUploadResult(NSURLResponse *response) const {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        // Failed to connect. We may be able to connect later.
        return UploadResult::FAILED_CAN_RETRY;
    }

    auto httpResponse = (NSHTTPURLResponse *_Nonnull)response;
    auto statusCode = httpResponse.statusCode;

    if (statusCode / 100 == 2) {
        return UploadResult::SUCCESSFUL;
    }

    if (statusCode / 100 == 4 &&
        statusCode != HTTPStatusCodePaymentRequired &&
        statusCode != HTTPStatusCodeProxyAuthenticationRequired &&
        statusCode != HTTPStatusCodeClientTimeout &&
        statusCode != HTTPStatusCodeTooManyRequests) {
        return UploadResult::FAILED_CANNOT_RETRY;
    }

    return UploadResult::FAILED_CAN_RETRY;
}

double OtlpUploader::getNewProbability(NSURLResponse *response) const {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        BSGLogDebug(@"getNewProbability(): Not an NSHTTPURLResponse, so returning -1");
        return -1;
    }

    auto httpResponse = (NSHTTPURLResponse *_Nonnull)response;
    NSString *probability = httpResponse.allHeaderFields[@"Bugsnag-Sampling-Probability"];
    if (probability) {
        BSGLogDebug(@"getNewProbability(): Bugsnag-Sampling-Probability = \"%@\", so returning %f", probability, probability.doubleValue);
        return probability.doubleValue;
    }

    BSGLogDebug(@"getNewProbability(): Bugsnag-Sampling-Probability not present, so returning -1");
    return -1;
}
