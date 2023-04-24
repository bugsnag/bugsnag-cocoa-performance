//
//  Startable.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

namespace bugsnag {

class Startable {
public:
    virtual void start() noexcept = 0;
    virtual ~Startable() {}
};

}

@protocol BSGStartable

- (void)start;

@end
