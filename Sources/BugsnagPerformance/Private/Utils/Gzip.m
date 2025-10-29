//
//  Gzip.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 20.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "Gzip.h"
#import <zlib.h>

@implementation Gzip

static const int kChunkSize = 1024;
static const int kMemoryLevel = 8;
static const int kWindowBits = 15;
static const int kWindowBitsWithGZipHeader = 16 + kWindowBits;

#define ERROR_DOMAIN @"com.bugsnag.performance.gzip"

+ (NSData *_Nullable)gzipped:(NSData *)data error:(NSError * __autoreleasing*)error {
    if (data.length == 0) {
        return data;
    }

    // Adapted from https://github.com/mattt/Godzippa/blob/master/Sources/NSData%2BGodzippa.m

// (z_const Bytef *) isn't actually const, which causes a loss-of-const warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-qual"
    z_stream zStream = {
        .zalloc = Z_NULL,
        .zfree = Z_NULL,
        .opaque = Z_NULL,
        .next_in = (z_const Bytef *)data.bytes,
        .avail_in = (unsigned int)data.length,
        .total_out = 0,
    };
#pragma clang diagnostic pop

    OSStatus status = deflateInit2(&zStream,
                                   Z_DEFAULT_COMPRESSION,
                                   Z_DEFLATED,
                                   kWindowBitsWithGZipHeader,
                                   kMemoryLevel,
                                   Z_DEFAULT_STRATEGY);
    if (status != Z_OK) {
        if (error != nil) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"deflateInit2 failed", nil)
                                                                 forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:ERROR_DOMAIN code:status userInfo:userInfo];
        }
        return nil;
    }

    NSMutableData *deflated = [NSMutableData dataWithLength:kChunkSize];

    do {
        if ((status == Z_BUF_ERROR) || (zStream.total_out == [deflated length])) {
            [deflated increaseLengthBy:kChunkSize];
        }

        zStream.next_out = (Bytef*)[deflated mutableBytes] + zStream.total_out;
        zStream.avail_out = (unsigned int)([deflated length] - zStream.total_out);
        status = deflate(&zStream, Z_FINISH);
    } while ((status == Z_OK) || (status == Z_BUF_ERROR));

    if ((status != Z_OK) && (status != Z_STREAM_END)) {
        if (error != nil) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"deflate failed", nil)
                                                                 forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:ERROR_DOMAIN code:status userInfo:userInfo];
        }
        return nil;
    }

    status = deflateEnd(&zStream);
    if (status != Z_OK) {
        if (error != nil) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"deflateEnd failed", nil)
                                                                 forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:ERROR_DOMAIN code:status userInfo:userInfo];
        }
        return nil;
    }

    [deflated setLength:zStream.total_out];
    return deflated;
}

@end
