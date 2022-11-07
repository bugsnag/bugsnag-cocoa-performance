//
//  BugsnagPerformanceUploader.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Uploader.h"
#import "OtlpPackage.h"
#import <memory>

namespace bugsnag {

class OtlpUploader: public Uploader {
public:
    OtlpUploader(NSURL *endpoint, NewProbabilityCallback newProbabilityCallback) noexcept
    : endpoint_(endpoint)
    , newProbabilityCallback_(newProbabilityCallback)
    {}
    virtual ~OtlpUploader() = default;

    void upload(OtlpPackage &package, UploadResultCallback callback) noexcept override;

private:
    const NSURL *endpoint_;
    NewProbabilityCallback newProbabilityCallback_;

    UploadResult getUploadResult(NSURLResponse *response) const;
    double getNewProbability(NSURLResponse *response) const;
};
}
