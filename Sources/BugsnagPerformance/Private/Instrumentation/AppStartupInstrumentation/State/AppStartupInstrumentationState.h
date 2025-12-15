//
//  AppStartupInstrumentationState.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/02/2025.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

#import "AppStartupInstrumentationStateSnapshot.h"

typedef NS_ENUM(uint8_t, BSGAppStartupStage) {
    BSGAppStartupStagePreMain = 0,
    BSGAppStartupStagePostMain = 1,
    BSGAppStartupStageUIInit = 3,
    BSGAppStartupStageActive = 4,
};

@interface AppStartupInstrumentationState: NSObject
@property (nonatomic, strong) BugsnagPerformanceSpan *appStartSpan;
@property (nonatomic, strong) BugsnagPerformanceSpan *preMainSpan;
@property (nonatomic, strong) BugsnagPerformanceSpan *postMainSpan;
@property (nonatomic, strong) BugsnagPerformanceSpan *uiInitSpan;
@property (nonatomic, strong) NSString *firstViewName;
@property (nonatomic, readonly) BOOL isInProgress;
@property (nonatomic) CFAbsoluteTime didStartProcessAtTime;
@property (nonatomic) CFAbsoluteTime didStartEarlyPhaseAtTime;
@property (nonatomic) CFAbsoluteTime didCallMainFunctionAtTime;
@property (nonatomic) CFAbsoluteTime didStartBugsnagPerformanceAtTime;
@property (nonatomic) CFAbsoluteTime didBecomeActiveAtTime;
@property (nonatomic) CFAbsoluteTime didFinishLaunchingAtTime;
@property (nonatomic) CFAbsoluteTime didEnterBackgroundAtTime;
@property (nonatomic) BOOL hasFirstView;
@property (nonatomic) BOOL isColdLaunch;
@property (nonatomic) BOOL isActivePrewarm;
@property (nonatomic) BOOL isDiscarded;
@property (nonatomic) BOOL didCheckEarlyStartDuration;
@property (nonatomic) BOOL shouldRespondToAppDidFinishLaunching;
@property (nonatomic) BOOL shouldRespondToAppDidBecomeActive;
@property (nonatomic) BOOL firstViewLoadWasCancelled;
@property (nonatomic) BSGAppStartupStage stage;

- (AppStartupInstrumentationStateSnapshot *)createSnapshot;

@end
