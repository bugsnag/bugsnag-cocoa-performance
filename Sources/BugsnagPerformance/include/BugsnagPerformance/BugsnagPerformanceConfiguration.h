//
//  BugsnagPerformanceConfiguration.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)loadConfig;

@property (nonatomic) NSURL *endpoint;

@end

NS_ASSUME_NONNULL_END
