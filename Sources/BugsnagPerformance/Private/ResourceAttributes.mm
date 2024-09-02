//
//  ResourceAttributes.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 02/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "ResourceAttributes.h"

#import "Version.h"

#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>

using namespace bugsnag;

static NSString *sysctlString(const char *name) noexcept {
    char value[32];
    auto size = sizeof value;
    if (sysctlbyname(name, value, &size, NULL, 0) == 0) {
        value[sizeof value - 1] = '\0';
        return [NSString stringWithCString:value encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

static NSString *deviceModelIdentifier() noexcept {
#if TARGET_OS_OSX || TARGET_OS_SIMULATOR || (defined(TARGET_OS_MACCATALYST) && TARGET_OS_MACCATALYST)
    return sysctlString("hw.model");
#else
    return sysctlString("hw.machine");
#endif
}

static NSString *hostArch() noexcept {
#if TARGET_CPU_ARM
    return @"arm32";
#elif TARGET_CPU_ARM64
    return @"arm64";
#elif TARGET_CPU_X86
    return @"x86";
#elif TARGET_CPU_X86_64
    return @"amd64";
#endif
}

static NSString *osName() noexcept {
#if TARGET_OS_IOS
    return @"iOS";
#else
#error Other platforms not supported yet
#endif
}

static NSString *osVersion() noexcept {
#if __has_include(<UIKit/UIDevice.h>)
    return UIDevice.currentDevice.systemVersion;
#else
#error Other platforms not supported yet
#endif
}

void ResourceAttributes::configure(BugsnagPerformanceConfiguration *config) noexcept {
    auto infoDictionary = NSBundle.mainBundle.infoDictionary;
    bundleVersion_ = (id)config.bundleVersion ?: infoDictionary[@"CFBundleVersion"] ?: [NSNull null];
    serviceName_ = (id)config.serviceName ?: NSBundle.mainBundle.bundleIdentifier ?: NSProcessInfo.processInfo.processName;
    serviceVersion_ = (id)config.appVersion ?: infoDictionary[@"CFBundleShortVersionString"] ?: [NSNull null];
    releaseStage_ = config.releaseStage;
}

void ResourceAttributes::preStartSetup() noexcept {
    cachedAttributes_ = @{
        @"bugsnag.app.bundle_version": bundleVersion_,

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/deployment_environment/
        @"deployment.environment": releaseStage_ ?: [NSNull null],

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/device/
        @"device.id": deviceID_->external(),
        @"device.manufacturer": @"Apple",
        @"device.model.identifier": deviceModelIdentifier() ?: [NSNull null],

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/host/
        @"host.arch": hostArch(),

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/os/
        @"os.name": osName(),
        @"os.type": @"darwin",
        @"os.version": osVersion() ?: [NSNull null],

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/#service
        @"service.name": serviceName_ ?: [NSNull null],
        @"service.version": serviceVersion_,

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/#telemetry-sdk
        @"telemetry.sdk.name": @ TELEMETRY_SDK_NAME,
        @"telemetry.sdk.version": @ TELEMETRY_SDK_VERSION,
    };
}
