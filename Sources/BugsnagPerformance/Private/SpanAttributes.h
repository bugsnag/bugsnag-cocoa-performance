//
//  SpanAttributes.h
//  BugsnagPerformance-iOS
//
//  Created by Nick Dowell on 03/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

namespace bugsnag {
class SpanAttributes {
public:
    static NSMutableDictionary *get() noexcept;
};
}
