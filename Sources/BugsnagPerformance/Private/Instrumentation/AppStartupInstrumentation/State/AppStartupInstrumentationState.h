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
@property (nonatomic) BOOL isInProgress;
@property (nonatomic) BOOL hasFirstView;
@end
