//
//  BugsnagPerformanceUploader.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OtlpPackage.h"
#import <memory>

namespace bugsnag {

typedef enum {
    BSG_UPLOAD_SUCCESSFUL,
    BSG_UPLOAD_FAILED_CAN_RETRY,
    BSG_UPLOAD_FAILED_CANNOT_RETRY,
} UploadResult;

typedef void (^NewProbabilityCallback)(double newProbability);
typedef void (^UploadResultCallback)(UploadResult result);

class BugsnagPerformanceUploader {
public:
    BugsnagPerformanceUploader(NSURL *endpoint, NewProbabilityCallback newProbabilityCallback) noexcept
    : endpoint_(endpoint)
    , newProbabilityCallback_(newProbabilityCallback)
    {}

    void upload(const OtlpPackage &package, UploadResultCallback callback) const noexcept;

private:
    const NSURL *endpoint_;
    NewProbabilityCallback newProbabilityCallback_;

    UploadResult getUploadResult(NSURLResponse *response) const;
    double getNewProbability(NSURLResponse *response) const;
};
}
