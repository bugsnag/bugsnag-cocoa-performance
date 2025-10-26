//
//  BugsnagPerformanceViewType.cpp
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 27.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceViewType+Private.h"

NSString *bugsnag::getBugsnagPerformanceViewTypeName(BugsnagPerformanceViewType viewType) noexcept {
    switch (viewType) {
        case BugsnagPerformanceViewTypeSwiftUI: return @"SwiftUI";
        case BugsnagPerformanceViewTypeUIKit:   return @"UIKit";
        default:                                return @"?";
    }
}
