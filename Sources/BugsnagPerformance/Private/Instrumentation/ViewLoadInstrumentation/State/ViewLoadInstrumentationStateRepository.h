//
//  ViewLoadInstrumentationStateRepository.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewLoadInstrumentationState.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadInstrumentationStateRepository {
public:
    virtual void setInstrumentationState(UIViewController *viewController, ViewLoadInstrumentationState * _Nullable state) noexcept = 0;
    virtual ViewLoadInstrumentationState *getInstrumentationState(UIViewController *viewController) noexcept = 0;
    virtual void setInstrumentationState(UIView *view, ViewLoadInstrumentationState * _Nullable state) noexcept = 0;
    virtual ViewLoadInstrumentationState *getInstrumentationState(UIView *view) noexcept = 0;
    virtual ~ViewLoadInstrumentationStateRepository() {}
};
}

NS_ASSUME_NONNULL_END
