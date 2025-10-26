//
//  JSON.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "JSON.h"

using namespace bugsnag;

static NSString *errorDomain = @"bugsnag::JSONErrorDomain";

static NSError* wrapException(NSException* exception) {
    return [NSError errorWithDomain:errorDomain code:1 userInfo:@{
        NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@: %@", exception.name, exception.reason]
    }];
}

static BOOL isValidForJson(NSDictionary *obj, NSError **error) {
    @try {
        if (![obj isKindOfClass:[NSDictionary class]] ||
            ![NSJSONSerialization isValidJSONObject:(id _Nonnull)obj]) {
            if (error) {
                *error = [NSError errorWithDomain:errorDomain code:0 userInfo:@{
                    NSLocalizedDescriptionKey: @"Not a valid JSON object"}];
            }
            return NO;
        }
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            *error = wrapException(exception);
        }
        return NO;
    }
}

NSDictionary *JSON::dataToDictionary(NSData *json, NSError **error) noexcept {
    @try {
        id obj = [NSJSONSerialization JSONObjectWithData:json options:0 error:error];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            return obj;
        }

        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Expected NSDictionary but got %@", [obj class]];
            *error = [NSError errorWithDomain:errorDomain code:0 userInfo:@{
                NSLocalizedDescriptionKey:msg}];
        }
        return nil;
    } @catch (NSException *exception) {
        if (error) {
            *error = wrapException(exception);
        }
        return nil;
    }
    return nil;
}

NSData *JSON::dictionaryToData(NSDictionary *dict, NSError **error) noexcept {
    if (!isValidForJson(dict, error)) {
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:dict options:0 error:error];
}

NSError *JSON::dictionaryToFile(NSString *path, NSDictionary *dict) noexcept {
    NSError *error = nil;
    NSData *data = JSON::dictionaryToData(dict, &error);
    if (data == nil) {
        return error;
    }
    if (![data writeToFile:path options:NSDataWritingAtomic error:&error]) {
        return error;
    }
    return nil;
}

NSDictionary *JSON::fileToDictionary(NSString *path, NSError **error) noexcept {
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:error];
    if (data == nil) {
        return nil;
    }
    return JSON::dataToDictionary(data, error);
}
