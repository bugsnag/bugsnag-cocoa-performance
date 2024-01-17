//
//  BugsnagPerformaceTrackedViewContainer.m
//  BugsnagPerformance
//
//  Created by Robert B on 04/01/2024.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformance.h>
#import <BugsnagPerformance/BugsnagPerformanceTrackedViewContainer.h>

@interface BugsnagPerformanceTrackedViewContainer()

@property (nonatomic, strong) UIViewController *viewController;

@end

@implementation BugsnagPerformanceTrackedViewContainer

+ (id)trackViewController:(UIViewController *)viewController {
    BugsnagPerformanceTrackedViewContainer *container = [BugsnagPerformanceTrackedViewContainer alloc];
    container.viewController = viewController;
    return container;
}

+ (BOOL)respondsToSelector:(SEL)aSelector {
    return YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.viewController methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    NSLog(@"Beginning invocation");
    [invocation setTarget:self.viewController];
    [invocation retainArguments];
    if ([NSStringFromSelector(invocation.selector) isEqual:@"respondsToSelector:"]) {
        SEL argument;
        [invocation getArgument:&argument atIndex:0];
        NSLog(@"ARGUMENTS %@", NSStringFromSelector(argument));
    }
    
    NSLog(@"INVOKING %@", NSStringFromSelector(invocation.selector));
    [invocation invoke];
    NSLog(@"INVOKED");
}

@end
