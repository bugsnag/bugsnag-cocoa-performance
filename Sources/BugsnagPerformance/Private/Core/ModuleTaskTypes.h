//
//  ModuleTaskTypes.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Utils/Reachability.h"

using namespace bugsnag;

typedef void (^ModuleTask)();
typedef void (^UpdateProbabilityTask)(double);
typedef void (^UpdateConnectivityTask)(Reachability::Connectivity);
typedef void (^HandleStringTask)(NSString *);
