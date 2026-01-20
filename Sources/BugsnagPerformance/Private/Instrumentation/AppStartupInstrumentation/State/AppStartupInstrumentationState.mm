//
//  AppStartupInstrumentationState.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/02/2025.
//

#import "AppStartupInstrumentationState.h"
#import "../../../BugsnagPerformanceSpan+Private.h"

@implementation AppStartupInstrumentationState

- (AppStartupInstrumentationStateSnapshot *)createSnapshot {
    return [AppStartupInstrumentationStateSnapshot snapshotWithAppStartSpan:self.appStartSpan
                                                                 uiInitSpan:self.uiInitSpan
                                                               isInProgress:self.isInProgress
                                                               hasFirstView:self.firstViewName != nil
                                                 shouldIncludeFirstViewLoad:self.shouldIncludeFirstViewLoad];
}

- (BOOL)isInProgress {
    return self.appStartSpan.isValid || self.appStartSpan.isBlocked;
}

- (BOOL)isLoadingUI {
    return !self.uiInitSpan.isValid && self.uiInitSpan.isBlocked;
}

@end
