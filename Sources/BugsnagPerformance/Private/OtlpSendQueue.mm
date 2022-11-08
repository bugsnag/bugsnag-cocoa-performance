//
//  OtlpSendQueue.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "OtlpSendQueue.h"

#import <utility>

using namespace bugsnag;

void OtlpSendQueue::push(std::unique_ptr<OtlpPackage> package) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    awaiting_.push_back(std::move(package));
}

std::unique_ptr<OtlpPackage> OtlpSendQueue::pop() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (awaiting_.size() == 0) {
        return nullptr;
    }
    auto next = std::move(awaiting_.front());
    awaiting_.pop_front();
    return next;
}
