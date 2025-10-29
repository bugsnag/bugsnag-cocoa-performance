//
//  ViewLoadEarlyPhaseHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadEarlyPhaseHandler.h"
#import "../../../../Tracer.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadEarlyPhaseHandlerImpl: public ViewLoadEarlyPhaseHandler {
public:
    ViewLoadEarlyPhaseHandlerImpl() noexcept
    : isEarlyPhase_(true)
    , earlyStates_([NSMutableArray array]) {}
    
    void onNewStateCreated(ViewLoadInstrumentationState *state) noexcept;
    void onEarlyPhaseEnded(bool isEnabled, __nullable BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept;
    
private:
    std::recursive_mutex mutex_;
    std::atomic<bool> isEarlyPhase_{true};
    NSMutableArray<ViewLoadInstrumentationState *> * _Nullable earlyStates_;
};
}

NS_ASSUME_NONNULL_END
