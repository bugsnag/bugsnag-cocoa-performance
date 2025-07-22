//
//  ViewLoadInstrumentationStateRepositoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadInstrumentationStateRepository.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadInstrumentationStateRepositoryImpl: public ViewLoadInstrumentationStateRepository {
public:
    ViewLoadInstrumentationStateRepositoryImpl() noexcept {}
    
    void setInstrumentationState(UIViewController *viewController, ViewLoadInstrumentationState * _Nullable state) noexcept;
    ViewLoadInstrumentationState *getInstrumentationState(UIViewController *viewController) noexcept;
    void setInstrumentationState(UIView *view, ViewLoadInstrumentationState * _Nullable state) noexcept;
    ViewLoadInstrumentationState *getInstrumentationState(UIView *view) noexcept;
};
}

NS_ASSUME_NONNULL_END
