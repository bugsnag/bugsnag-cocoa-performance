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

// Used to compute deviceId; mimics +[BSG_KSSystemInfo CPUArchForCPUType:subType:]
static NSString *cpuType() noexcept {
    cpu_type_t cpuType = 0;
    auto size = sizeof cpuType;
    if (sysctlbyname("hw.cputype", &cpuType, &size, NULL, 0) != 0) {
        return nil;
    }
    
    cpu_subtype_t subType = 0;
    size = sizeof subType;
    if (sysctlbyname("hw.cpusubtype", &subType, &size, NULL, 0) != 0) {
        return nil;
    }
    
    switch (cpuType) {
        case CPU_TYPE_ARM: {
            switch (subType) {
                case CPU_SUBTYPE_ARM_V6:
                    return @"armv6";
                case CPU_SUBTYPE_ARM_V7:
                    return @"armv7";
                case CPU_SUBTYPE_ARM_V7F:
                    return @"armv7f";
                case CPU_SUBTYPE_ARM_V7K:
                    return @"armv7k";
#ifdef CPU_SUBTYPE_ARM_V7S
                case CPU_SUBTYPE_ARM_V7S:
                    return @"armv7s";
#endif
                case CPU_SUBTYPE_ARM_V8:
                    return @"armv8";
            }
            break;
        }
        case CPU_TYPE_ARM64: {
            switch (subType) {
                case CPU_SUBTYPE_ARM64E:
                    return @"arm64e";
                default:
                    return @"arm64";
            }
        }
        case CPU_TYPE_ARM64_32: {
            // Ignore arm64_32_v8 subtype
            return @"arm64_32";
        }
        case CPU_TYPE_X86:
            return @"x86";
        case CPU_TYPE_X86_64:
            return @"x86_64";
    }
    
    return nil;
}

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

/// Returns a device ID that matches +[BSG_KSSystemInfo deviceAndAppHash]
static NSString *deviceId() noexcept {
    CC_SHA1_CTX sha1;
    CC_SHA1_Init(&sha1);
    
#if __has_include(<UIKit/UIDevice.h>)
    uuid_t uuid = {0};
    [UIDevice.currentDevice.identifierForVendor getUUIDBytes:uuid];
    CC_SHA1_Update(&sha1, uuid, sizeof uuid);
#else
#error Other platforms not supported yet
#endif
    
    if (auto data = [sysctlString("hw.machine") dataUsingEncoding:NSUTF8StringEncoding]) {
        CC_SHA1_Update(&sha1, data.bytes, (CC_LONG)data.length);
    }
    
    if (auto data = [sysctlString("hw.model") dataUsingEncoding:NSUTF8StringEncoding]) {
        CC_SHA1_Update(&sha1, data.bytes, (CC_LONG)data.length);
    }
    
    if (auto data = [cpuType() dataUsingEncoding:NSUTF8StringEncoding]) {
        CC_SHA1_Update(&sha1, data.bytes, (CC_LONG)data.length);
    }
    
    if (auto data = [NSBundle.mainBundle.bundleIdentifier dataUsingEncoding:NSUTF8StringEncoding]) {
        CC_SHA1_Update(&sha1, data.bytes, (CC_LONG)data.length);
    }
    
    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(md, &sha1);
    
    char hex[2 * sizeof md];
    for (size_t i = 0; i < sizeof md; i++) {
        static char chars[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
        hex[i * 2 + 0] = chars[(md[i] & 0xf0) >> 4];
        hex[i * 2 + 1] = chars[(md[i] & 0x0f)];
    }
    return [[NSString alloc] initWithBytes:hex length:sizeof hex encoding:NSASCIIStringEncoding];
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
    serviceVersion_ = (id)config.appVersion ?: infoDictionary[@"CFBundleShortVersionString"] ?: [NSNull null];
    releaseStage_ = config.releaseStage;
}

void ResourceAttributes::start() noexcept {
    cachedAttributes_ = @{
        @"bugsnag.app.bundle_version": bundleVersion_,

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/deployment_environment/
        @"deployment.environment": releaseStage_ ?: [NSNull null],

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/device/
        @"device.id": deviceId(),
        @"device.manufacturer": @"Apple",
        @"device.model.identifier": deviceModelIdentifier() ?: [NSNull null],

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/host/
        @"host.arch": hostArch(),

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/os/
        @"os.name": osName(),
        @"os.type": @"darwin",
        @"os.version": osVersion() ?: [NSNull null],

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/#service
        @"service.name": NSBundle.mainBundle.bundleIdentifier ?: NSProcessInfo.processInfo.processName,
        @"service.version": serviceVersion_,

        // https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/#telemetry-sdk
        @"telemetry.sdk.name": @ TELEMETRY_SDK_NAME,
        @"telemetry.sdk.version": @ TELEMETRY_SDK_VERSION,
    };
}
