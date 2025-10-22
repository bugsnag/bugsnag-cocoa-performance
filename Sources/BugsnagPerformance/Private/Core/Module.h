//
//  Module.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "PhasedStartup.h"
#import "ModuleTaskTypes.h"

namespace bugsnag {
class Module: public PhasedStartup {
public:
    virtual void setUp() noexcept = 0;
    
    virtual ~Module() {};
};
}
