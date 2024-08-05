//
//  ErrorGenerator.m
//  Fixture
//
//  Created by Karl Stenerud on 26.07.24.
//

#import "ErrorGenerator.h"
#import "Fixture-Swift.h"

@interface ErrorGenerator ()

@property(nonatomic,readwrite) SwiftErrorGenerator *swiftErrorGenerator;

@end

@implementation ErrorGenerator

- (instancetype)init {
    if ((self = [super init])) {
        _swiftErrorGenerator = [[SwiftErrorGenerator alloc] init];
    }
    return self;
}

- (void)throwObjCException {
    [NSException raise:@"MyException" format:@"Oops..."];
}

- (NSError *)throwSwiftException {
    NSError *error = nil;
    [self.swiftErrorGenerator throwSwiftErrorAndReturnError:&error];
    return error;
}

@end
