//
//  ViewLoadEarlyPhaseHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "../State/ViewLoadInstrumentationState.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadEarlyPhaseHandler {
public:
    virtual void onNewStateCreated(ViewLoadInstrumentationState *state) noexcept = 0;
    virtual void onEarlyPhaseEnded(bool isEnabled, __nullable BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept = 0;
    virtual ~ViewLoadEarlyPhaseHandler() {}
};
}

NS_ASSUME_NONNULL_END
