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

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)loadConfig;

@property (nonatomic) BOOL autoInstrumentAppStarts;

@property (nonatomic) BOOL autoInstrumentViewControllers;

@property (nonatomic) BOOL autoInstrumentNetwork;

@property (nonatomic) NSURL *endpoint;

@property (nullable, nonatomic) BugsnagPerformanceViewControllerInstrumentationCallback viewControllerInstrumentationCallback;

@end

NS_ASSUME_NONNULL_END
