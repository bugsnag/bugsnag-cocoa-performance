//
//  Reachability.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 03/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "Reachability.h"

using namespace bugsnag;

Reachability &
Reachability::get() noexcept {
    [[clang::no_destroy]] static Reachability instance;
    return instance;
}

Reachability::Reachability() noexcept {
    queue_ = dispatch_queue_create("bugsnag.performance.reachability", nullptr);
    target_ = SCNetworkReachabilityCreateWithName(nullptr, "bugsnag.com");
    if (target_) {
        SCNetworkReachabilitySetCallback(target_, callback, &context_);
        SCNetworkReachabilitySetDispatchQueue(target_, queue_);
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(target_, &flags)) {
            callback(target_, flags, this);
        }
    }
}

void
Reachability::callback(__unused SCNetworkReachabilityRef target,
                       SCNetworkReachabilityFlags flags,
                       void *info) noexcept {
    auto This = reinterpret_cast<Reachability *>(info);
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
            This->connectivity_ = Connectivity::Cellular;
        } else {
            This->connectivity_ = Connectivity::Wifi;
        }
    } else {
        This->connectivity_ = Connectivity::None;
    }
    
    std::for_each(std::begin(This->callbacks_), std::end(This->callbacks_), [This](auto callback) {
        callback(This->connectivity_);
    });
}

void
Reachability::addCallback(void (^callback)(Connectivity)) {
    callbacks_.push_back(callback);
}
