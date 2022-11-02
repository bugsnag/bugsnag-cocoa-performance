//
//  BugsnagPerformanceConfiguration.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

@implementation BugsnagPerformanceConfiguration

- (instancetype)init {
    if ((self = [super init])) {
        _autoInstrumentAppStarts = YES;
        _autoInstrumentViewControllers = YES;
#if defined(DEBUG) && DEBUG
        _releaseStage = @"development";
#else
        _releaseStage = @"production";
#endif
        _samplingProbability = 1.0;
        _endpoint = (NSURL *_Nonnull)[NSURL URLWithString:@"https://127.0.0.0"];
    }
    return self;
}

+ (instancetype)loadConfig {
    return [BugsnagPerformanceConfiguration new];
}

@end
