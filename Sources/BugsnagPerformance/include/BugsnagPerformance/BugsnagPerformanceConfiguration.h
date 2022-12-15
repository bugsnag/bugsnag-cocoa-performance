//
//  BugsnagPerformanceConfiguration.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^ BugsnagPerformanceViewControllerInstrumentationCallback)(UIViewController *viewController);

OBJC_EXPORT
@interface BugsnagPerformanceConfiguration : NSObject

- (instancetype)initWithApiKey:(NSString *)apiKey NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)loadConfig;

- (void) validate;

@property (nonatomic) NSString *apiKey;

@property (nonatomic) NSURL *endpoint;

@property (nonatomic) BOOL autoInstrumentAppStarts;

@property (nonatomic) BOOL autoInstrumentViewControllers;

@property (nonatomic) BOOL autoInstrumentNetwork;

@property (nonatomic) double samplingProbability;

@property (nullable, nonatomic) BugsnagPerformanceViewControllerInstrumentationCallback viewControllerInstrumentationCallback;

@end

@interface BugsnagPerformanceConfiguration (/* App metadata */)

@property (copy, nonatomic) NSString *releaseStage;

@end

NS_ASSUME_NONNULL_END
