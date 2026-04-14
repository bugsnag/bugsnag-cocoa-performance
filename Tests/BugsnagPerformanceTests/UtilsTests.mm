//
//  UtilsTests.mm
//  BugsnagPerformance-iOSTests
//
//  Created by Meiyalagan on 14.04.26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#import "TestHelpers.h"
#import "Utils.h"

using namespace bugsnag;

@interface UtilsTests : XCTestCase

@end

@implementation UtilsTests

- (void)testBSGNormalizePathHandlesNilAndRootAndTrailingSlash {
    XCTAssertEqualObjects(BSGNormalizePath(nil), @"/");
    XCTAssertEqualObjects(BSGNormalizePath(@""), @"/");
    XCTAssertEqualObjects(BSGNormalizePath(@"/"), @"/");
    XCTAssertEqualObjects(BSGNormalizePath(@"/v1/traces"), @"/v1/traces");
    XCTAssertEqualObjects(BSGNormalizePath(@"/v1/traces/"), @"/v1/traces");
    XCTAssertEqualObjects(BSGNormalizePath(@"/a/"), @"/a");
}

- (void)testBSGNormalizedPortExplicitAndDefaultsAndUnknown {
    NSURL *u1 = [NSURL URLWithString:@"https://example.com:8443/"];
    XCTAssertEqual(BSGNormalizedPort(u1), 8443);

    NSURL *u2 = [NSURL URLWithString:@"https://example.com/"];
    XCTAssertEqual(BSGNormalizedPort(u2), 443);

    NSURL *u3 = [NSURL URLWithString:@"http://example.com/"];
    XCTAssertEqual(BSGNormalizedPort(u3), 80);

    NSURL *u4 = [NSURL URLWithString:@"ftp://example.com/"];
    XCTAssertEqual(BSGNormalizedPort(u4), -1);

    // nil URL should return -1
    XCTAssertEqual(BSGNormalizedPort(nil), -1);
}

- (void)testBSGURLsMatchSchemeHostPortPathVariants {
    NSURL *a = [NSURL URLWithString:@"https://example.com/v1/traces"];
    NSURL *b = [NSURL URLWithString:@"https://example.com/v1/traces/"];
    XCTAssertTrue(BSGURLsMatchSchemeHostPortPath(a, b));

    // Query params ignored
    NSURL *c = [NSURL URLWithString:@"https://example.com/v1/traces?x=y"];
    XCTAssertTrue(BSGURLsMatchSchemeHostPortPath(a, c));

    // Scheme case-insensitive
    NSURL *d = [NSURL URLWithString:@"HTTPS://example.com/v1/traces"];
    XCTAssertTrue(BSGURLsMatchSchemeHostPortPath(a, d));

    // Host case-insensitive
    NSURL *e = [NSURL URLWithString:@"https://EXAMPLE.com/v1/traces"];
    XCTAssertTrue(BSGURLsMatchSchemeHostPortPath(a, e));

    // Default port vs explicit port
    NSURL *f = [NSURL URLWithString:@"https://example.com:443/v1/traces"];
    XCTAssertTrue(BSGURLsMatchSchemeHostPortPath(a, f));

    // Different ports
    NSURL *g = [NSURL URLWithString:@"https://example.com:8443/v1/traces"];
    XCTAssertFalse(BSGURLsMatchSchemeHostPortPath(a, g));

    // Different path
    NSURL *h = [NSURL URLWithString:@"https://example.com/v1/other"];
    XCTAssertFalse(BSGURLsMatchSchemeHostPortPath(a, h));

    // Nil handling
    XCTAssertFalse(BSGURLsMatchSchemeHostPortPath(nil, a));
    XCTAssertFalse(BSGURLsMatchSchemeHostPortPath(a, nil));
    
    NSURL *hostMismatch = [NSURL URLWithString:@"https://example2.com/v1/traces"];
    XCTAssertFalse(BSGURLsMatchSchemeHostPortPath(a, hostMismatch));

    NSURL *schemeMismatch = [NSURL URLWithString:@"http://example.com/v1/traces"];
    XCTAssertFalse(BSGURLsMatchSchemeHostPortPath(a, schemeMismatch));
}

@end
