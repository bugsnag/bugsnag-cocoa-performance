//
//  Persistence.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

namespace bugsnag {

class Persistence {
public:
    Persistence() = delete;
    Persistence(NSString *topLevelDir) noexcept;
    NSError *start(void) noexcept;
    NSError *clear(void) noexcept;
    NSString *topLevelDirectory(void) noexcept;
private:
    NSString *topLevelDir_;
};

}
