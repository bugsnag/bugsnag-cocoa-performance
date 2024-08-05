//
//  ErrorGenerator.h
//  Fixture
//
//  Created by Karl Stenerud on 26.07.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ErrorGenerator : NSObject

- (void)throwObjCException;
- (NSError *)throwSwiftException;

@end

NS_ASSUME_NONNULL_END
