//
//  OtlpTraceEncoding.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 27/09/2022.
//

#pragma once

#import <Foundation/Foundation.h>

#import "OtlpPackage.h"
#import "../../Core/Span/BugsnagPerformanceSpan+Private.h"
#import "../../Core/PhasedStartup.h"

#import <vector>

namespace bugsnag {
class OtlpTraceEncoding: public PhasedStartup {

public:
    /**
     * Build a package suitable for upload to the backend server.
     */
    std::unique_ptr<OtlpPackage> buildUploadPackage(NSArray<BugsnagPerformanceSpan *> *spans, NSDictionary *resourceAttributes, bool includeSamplingHeader) noexcept;

    std::unique_ptr<OtlpPackage> buildPValueRequestPackage() noexcept;

public: // PhasedStartup

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {};
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        attributeStringValueLimit_ = config.attributeStringValueLimit;
        attributeArrayLengthLimit_ = config.attributeArrayLengthLimit;
    };
    void preStartSetup() noexcept {};
    void start() noexcept {}

public: // Public for testing only
    NSDictionary * encode(BugsnagPerformanceSpan *span) noexcept;

    NSDictionary * encode(NSArray<BugsnagPerformanceSpan *> *spans, NSDictionary *resourceAttributes) noexcept;

    NSArray<NSDictionary *> * encode(NSDictionary *attributes) noexcept;

    NSArray<NSDictionary *> * encode(NSArray *arrayAttribute) noexcept;

private:
    uint64_t attributeStringValueLimit_{1000};
    uint64_t attributeArrayLengthLimit_{1000};

    void encodeStringAttribute(NSMutableArray *destination, NSString *key, NSString *value);
    void encodeArrayAttribute(NSMutableArray *destination, NSString *key, NSArray *value);
    void encodeNumberAttribute(NSMutableArray *destination, NSString *key, NSNumber *value);
};
}
