//
//  OtlpTraceEncoding.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 27/09/2022.
//

#pragma once

#import <Foundation/Foundation.h>

#import "OtlpPackage.h"
#import "BugsnagPerformanceSpan+Private.h"

#import <vector>

namespace bugsnag {
class OtlpTraceEncoding {

public:
    /**
     * Build a package suitable for upload to the backend server.
     */
    static std::unique_ptr<OtlpPackage> buildUploadPackage(NSArray<BugsnagPerformanceSpan *> *spans, NSDictionary *resourceAttributes, bool includeSamplingHeader) noexcept;

    static std::unique_ptr<OtlpPackage> buildPValueRequestPackage() noexcept;

public: // Public for testing only
    static NSDictionary * encode(BugsnagPerformanceSpan *span) noexcept;
    
    static NSDictionary * encode(NSArray<BugsnagPerformanceSpan *> *spans, NSDictionary *resourceAttributes) noexcept;
    
    static NSArray<NSDictionary *> * encode(NSDictionary *attributes) noexcept;

    static NSArray<NSDictionary *> * encode(NSArray *arrayAttribute) noexcept;
};
}
