//
//  NetworkInstrumentationStateRepository.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "NetworkInstrumentationState.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class NetworkInstrumentationStateRepository {
public:
    virtual void setInstrumentationState(NSURLSessionTask *task, NetworkInstrumentationState * _Nullable state) noexcept = 0;
    virtual NetworkInstrumentationState *getInstrumentationState(NSURLSessionTask *task) noexcept = 0;
    virtual ~NetworkInstrumentationStateRepository() {}
};
}

NS_ASSUME_NONNULL_END
