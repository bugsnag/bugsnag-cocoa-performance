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

- (instancetype _Nullable)initWithApiKey:(NSString *)apiKey error:(NSError **)error NS_SWIFT_NAME(init(apiKey:)) NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype _Nullable)loadConfig:(NSError **)error NS_SWIFT_NAME(loadConfig());

- (BOOL) validate:(NSError * __autoreleasing _Nullable *)error NS_SWIFT_NAME(validate());

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
