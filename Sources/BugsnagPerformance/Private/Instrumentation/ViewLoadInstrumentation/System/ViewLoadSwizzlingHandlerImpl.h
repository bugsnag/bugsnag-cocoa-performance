//
//  ViewLoadSwizzlingHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "ViewLoadSwizzlingHandler.h"
#import <map>
#import <mutex>

namespace bugsnag {

class ViewLoadSwizzlingHandlerImpl: public ViewLoadSwizzlingHandler {
public:
    void instrument(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept;
    void instrumentInit(Class cls, ViewLoadSwizzlingCallbacks *callbacks, bool *isEnabled) noexcept;
    
private:
    std::map<Class, bool> classToIsObserved_{};
    std::recursive_mutex vcInitMutex_;
    
    bool isClassObserved(Class cls) noexcept;
};
}
