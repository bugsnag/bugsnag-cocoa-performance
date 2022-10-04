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
        // Inspect @ https://webhook.site/#!/14b03305-a46e-4e1f-b8b4-8434643631dc
        _endpoint = [NSURL URLWithString:@"https://webhook.site/14b03305-a46e-4e1f-b8b4-8434643631dc"];
    }
    return self;
}

+ (instancetype)loadConfig {
    return [BugsnagPerformanceConfiguration new];
}

@end
