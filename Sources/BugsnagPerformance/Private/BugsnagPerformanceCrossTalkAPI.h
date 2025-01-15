//
//  BugsnagPerformanceCrossTalkAPI.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.05.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

// Bugsnag CrossTalk API
//
// CrossTalk is an Objective-C layer for sharing private APIs between Bugsnag libraries.
// It allows client libraries to call internal functions of this one without the usual
// worries of breaking downstream clients whenever internal code changes.
//
// This code should be duplicated and used as a template for any Bugsnag Objective-C
// library that wants to expose its API to other Bugsnag libraries.
//
// NOTE: Your CrossTalk class name MUST be unique or else it will clash with another
//       Bugsnag library's CrossTalk class name.
//
// See CrossTalkTests.mm for an example of how to use CrossTalk from a client library.
// It contains a full example for how to set up a client library to call this one.

#import <Foundation/Foundation.h>
#import <memory>
#import "PhasedStartup.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {
class SpanStackingHandler;
class Tracer;
}

@interface BugsnagPerformanceCrossTalkAPI : NSObject<BSGPhasedStartup>

+ (instancetype) sharedInstance;

/**
 * Use the initialize method to pass any information this CrossTalk API requires to function.
 */
+ (void)initializeWithSpanStackingHandler:(std::shared_ptr<bugsnag::SpanStackingHandler>) handler tracer:(std::shared_ptr<bugsnag::Tracer>) tracer;

@end

/**
 * A very permissive proxy that won't crash if a method or property doesn't exist.
 *
 * When returning instances of Bugsnag classes, wrap them in this proxy so that
 * they don't crash when that class's API changes.
 *
 * WARNING: Returning internal classes is effectively creating a contract between Bugsnag libraries!
 * Be VERY conservative about any internal class you expose, because its interfaces will effectively
 * be "published", and changing a method's signature could break client libraries that use it.
 *
 * Adding/removing methods/properties is fine, but changing signatures WILL break things.
 *
 * Some ways to protect against breakage due to changed method signatures:
 * - Convert to maps and arrays instead
 * - Create custom classes designed specifically for library interop
 * - Create versioned wrapper methods in the classes and access those instead (doStuffV1, doStuffV2, etc)
 */
@interface BugsnagPerformanceCrossTalkProxiedObject : NSProxy

+ (instancetype _Nullable) proxied:(id _Nullable)delegate;

@end

NS_ASSUME_NONNULL_END
