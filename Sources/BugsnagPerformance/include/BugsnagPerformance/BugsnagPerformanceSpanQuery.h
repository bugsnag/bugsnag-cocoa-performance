//
//  BugsnagPerformanceSpanQuery.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpanQuery: NSObject

@property (nonatomic, readonly, nullable) Class resultType;

/**
 * Query for the expected result type.
 *
 * @param resultType the expected result type
 * @return a query for the expected result type
 */
+ (instancetype)queryWithResultType:(Class)resultType;

/**
 * Query for the expected result type and attributes.
 *
 * @param resultType the expected result type
 * @param attributes attributes for the query
 * @return a query for the expected result type with attributes
 */
+ (instancetype)queryWithResultType:(Class)resultType attributes:(NSDictionary<NSString *, id> *)attributes;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Get attribute value for the provided name
 *
 * @param name name of the attribute
 * @return attribute value or nil if it does not exist
 */
- (__nullable id)getAttributeWithName:(NSString *)name;

@end

/**
 * Mutable version of BugsnagPerformanceSpanQuery
 */
@interface BugsnagPerformanceMutableSpanQuery: BugsnagPerformanceSpanQuery

/**
 * Set the expected result type
 */
- (void)setResultType:(Class)type;

/**
 * Set attribute value
 *
 * @param name attribute name
 * @param value new attribute value
 */
- (void)setAttributeWithName:(NSString *)name value:(id)value;

@end

NS_ASSUME_NONNULL_END
