//
//  AppStartupInstrumentationState.h
//  BugsnagPerformance
//
//  Created by Robert B on 20/02/2025.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

@interface AppStartupInstrumentationState: NSObject
@property (nonatomic, strong) BugsnagPerformanceSpan *appStartSpan;
@property (nonatomic, strong) BugsnagPerformanceSpan *preMainSpan;
@property (nonatomic, strong) BugsnagPerformanceSpan *postMainSpan;
@property (nonatomic, strong) BugsnagPerformanceSpan *uiInitSpan;
@property (nonatomic, strong) NSString *firstViewName;
@property (nonatomic) CFAbsoluteTime didStartProcessAtTime;
@property (nonatomic) CFAbsoluteTime didCallMainFunctionAtTime;
@property (nonatomic) CFAbsoluteTime didBecomeActiveAtTime;
@property (nonatomic) CFAbsoluteTime didFinishLaunchingAtTime;
@property (nonatomic) BOOL isInProgress;
@property (nonatomic) BOOL hasFirstView;
@property (nonatomic) BOOL isColdLaunch;
@property (nonatomic) BOOL shouldRespondToAppDidFinishLaunching;
@property (nonatomic) BOOL shouldRespondToAppDidBecomeActive;
@end
