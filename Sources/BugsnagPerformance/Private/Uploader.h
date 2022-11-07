//
//  Uploader.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 07.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

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

class Uploader {
public:
    virtual ~Uploader() = default;

    virtual void upload(OtlpPackage &package, UploadResultCallback callback) noexcept = 0;
};
}
