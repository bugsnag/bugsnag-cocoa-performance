//
//  AppStartupInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <Foundation/Foundation.h>
#import <mutex>

@interface AppStartupInstrumentation: NSObject

+ (instancetype)sharedInstance;

- (void)disable;
- (void)didStartViewLoadSpanNamed:(NSString *)name;

@end
