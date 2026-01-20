//
//  NetworkInstrumentationStateRepositoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkInstrumentationStateRepository.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class NetworkInstrumentationStateRepositoryImpl: public NetworkInstrumentationStateRepository {
public:
    NetworkInstrumentationStateRepositoryImpl() noexcept {}
    
    void setInstrumentationState(NSURLSessionTask *task, NetworkInstrumentationState * _Nullable state) noexcept;
    NetworkInstrumentationState *getInstrumentationState(NSURLSessionTask *task) noexcept;
};
}

NS_ASSUME_NONNULL_END
