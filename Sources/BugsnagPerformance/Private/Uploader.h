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

enum class UploadResult {
    SUCCESSFUL,
    FAILED_CAN_RETRY,
    FAILED_CANNOT_RETRY,
};

using NewProbabilityCallback = void (^)(double newProbability);
using UploadResultCallback = void (^)(UploadResult result);

/**
 * An uploader attempts to send a package to a server, and informs the result via callback.
 */
class Uploader {
public:
    virtual ~Uploader() = default;

    virtual void upload(OtlpPackage &package, UploadResultCallback callback) noexcept = 0;
};
}
