//
//  OtlpSendQueue.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <memory>
#import <deque>
#import <mutex>

#import "OtlpPackage.h"

namespace bugsnag {
class OtlpSendQueue {
public:
    void push(std::unique_ptr<OtlpPackage> package) noexcept;
    std::unique_ptr<OtlpPackage> pop() noexcept;
private:
    std::mutex mutex_;
    std::deque<std::unique_ptr<OtlpPackage>> awaiting_;
};
}
