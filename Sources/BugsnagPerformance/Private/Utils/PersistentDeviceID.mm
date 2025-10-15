//
//  PersistentDeviceID.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 16.06.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "PersistentDeviceID.h"
#import "../Version.h"
#import "JSON.h"
#import "Filesystem.h"

#if __has_include(<UIKit/UIDevice.h>)
#import <UIKit/UIKit.h>
#endif
#if __has_include(<WatchKit/WatchKit.h>)
#import <WatchKit/WatchKit.h>
#endif
#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>
#import <mach/machine.h>

using namespace bugsnag;

// Used to compute deviceId; mimics +[BSG_KSSystemInfo CPUArchForCPUType:subType:]
static NSString *cpuArch() noexcept {
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

static NSData * _Nonnull dataForString(NSString *str) noexcept {
    if (str == nil) {
        return [NSData data];
    }
    return (NSData * _Nonnull)[str dataUsingEncoding:NSUTF8StringEncoding];
}

static bool isAllZeroes(NSData *data) {
    const uint8_t *bytes = (const uint8_t*)data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        if (bytes[i] != 0) {
            return false;
        }
    }
    return true;
}

static NSMutableData * _Nonnull generateIdentificationData() {
    NSMutableData *data = nil;

#if TARGET_OS_WATCH
    data = [NSMutableData dataWithLength:16];
    [[[WKInterfaceDevice currentDevice] identifierForVendor] getUUIDBytes:(uint8_t*)data.mutableBytes];
#elif __has_include(<UIKit/UIDevice.h>)
    data = [NSMutableData dataWithLength:16];
    [[UIDevice currentDevice].identifierForVendor getUUIDBytes:(uint8_t*)data.mutableBytes];
#else
    data = [NSMutableData dataWithLength:6];
    bsg_kssysctl_getMacAddress(BSGKeyDefaultMacName, [data mutableBytes]);
#endif

    if (isAllZeroes(data)) {
        // If we failed to get an initial identifier via Apple APIs, generate a random one.
        data = [NSMutableData dataWithLength:16];
        [[NSUUID UUID] getUUIDBytes:(uint8_t *)data.mutableBytes];
    }

    // Append some device-specific data.
    [data appendData:dataForString(sysctlString("hw.machine"))];
    [data appendData:dataForString(sysctlString("hw.model"))];
    [data appendData:dataForString(cpuArch())];

    // Append the bundle ID.
    [data appendData:dataForString(NSBundle.mainBundle.bundleIdentifier)];

    return data;
}

static NSString * _Nonnull computeHash(NSData * _Nullable data) {
    // SHA the whole thing.
    uint8_t sha[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([data bytes], (CC_LONG)[data length], sha);

    NSMutableString *hash = [NSMutableString string];
    for (size_t i = 0; i < sizeof(sha); i++) {
        [hash appendFormat:@"%02x", sha[i]];
    }

    return hash;
}

static NSString * _Nonnull generateExternalDeviceID() {
    return computeHash(generateIdentificationData());
}

static NSString * _Nonnull generateInternalDeviceID() {
    // ROAD-1488: internal device ID should be different.
    uint8_t additionalData[] = {251};
    NSMutableData *data = generateIdentificationData();
    [data appendBytes:additionalData length:sizeof(additionalData)];
    return computeHash(data);
}

static NSString *getString(NSDictionary* dict, NSString *key) {
    NSString *value = dict[key];
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

NSString *PersistentDeviceID::getFilePath() {
    return [persistenceDir_ stringByAppendingPathComponent:@"device-id.json"];
}

NSError *PersistentDeviceID::load() {
    NSError *error = nil;
    NSDictionary *dict = JSON::fileToDictionary(getFilePath(), &error);
    if (error != nil) {
        return error;
    }

    externalDeviceID_ = getString(dict, @"deviceID");
    internalDeviceID_ = getString(dict, @"internalDeviceID");
    return nil;
}

NSError *PersistentDeviceID::save() {
    NSError *error = [Filesystem ensurePathExists:persistenceDir_];
    if (error != nil) {
        return error;
    }

    return JSON::dictionaryToFile(getFilePath(), @{
        @"deviceID": externalDeviceID_,
        @"internalDeviceID": internalDeviceID_,
    });
}

void PersistentDeviceID::preStartSetup() noexcept {
    persistenceDir_ = persistence_->bugsnagSharedDir();
    load();

    bool requiresSave = false;
    if (externalDeviceID_.length == 0) {
        externalDeviceID_ = generateExternalDeviceID();
        requiresSave = true;
    }

    if (internalDeviceID_.length == 0) {
        internalDeviceID_ = generateInternalDeviceID();
        requiresSave = true;
    }

    if (requiresSave) {
        save();
    }
}
