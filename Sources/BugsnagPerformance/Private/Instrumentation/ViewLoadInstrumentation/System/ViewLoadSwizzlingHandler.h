//
//  ViewLoadSwizzlingHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "ViewLoadSwizzlingCallbacks.h"

namespace bugsnag {

class ViewLoadSwizzlingHandler {
public:
    virtual void instrument(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept = 0;
    virtual void instrumentInit(Class cls, ViewLoadSwizzlingCallbacks *callbacks, bool *isEnabled) noexcept = 0;
    virtual ~ViewLoadSwizzlingHandler() {}
};
}
