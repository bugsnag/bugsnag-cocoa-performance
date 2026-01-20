//
//  NetworkInstrumentationSystemUtilsImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkInstrumentationSystemUtils.h"

namespace bugsnag {

class NetworkInstrumentationSystemUtilsImpl: public NetworkInstrumentationSystemUtils {
public:
    NSArray<Class> *taskClassesToInstrument() noexcept;
    NSURLRequest *taskRequest(NSURLSessionTask *task, NSError **error) noexcept;
    NSURLRequest *taskCurrentRequest(NSURLSessionTask *task, NSError **error) noexcept;
};
}
