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
        _endpoint = [NSURL URLWithString:@"https://127.0.0.0"];
    }
    return self;
}

+ (instancetype)loadConfig {
    return [BugsnagPerformanceConfiguration new];
}

@end
