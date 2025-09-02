//
//  NetworkInstrumentationSystemUtils.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

namespace bugsnag {

class NetworkInstrumentationSystemUtils {
public:
    virtual NSArray<Class> *taskClassesToInstrument() noexcept = 0;
    virtual ~NetworkInstrumentationSystemUtils() {}
};
}
