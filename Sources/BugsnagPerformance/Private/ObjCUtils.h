//
//  ObjCUtils.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 30.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

namespace bugsnag {

NSURL * _Nullable nsurlWithString(NSString * _Nonnull str, NSError * __autoreleasing _Nullable * _Nullable error);

}

