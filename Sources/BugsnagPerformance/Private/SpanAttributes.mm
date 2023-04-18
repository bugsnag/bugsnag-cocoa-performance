//
//  SpanAttributes.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 03/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "SpanAttributes.h"

#import "BugsnagPerformanceLibrary.h"
#import "AppStateTracker.h"

using namespace bugsnag;

static NSString *hostConnectionType() noexcept {
    switch (BugsnagPerformanceLibrary::getReachability()->getConnectivity()) {
        case bugsnag::Reachability::Unknown:    return @"unknown";
        case bugsnag::Reachability::None:       return @"unavailable";
        case bugsnag::Reachability::Cellular:   return @"cell";
        case bugsnag::Reachability::Wifi:       return @"wifi";
    }
}

NSDictionary *
SpanAttributes::get() noexcept {
    return @{
        @"bugsnag.app.in_foreground": @(BugsnagPerformanceLibrary::getAppStateTracker().isInForeground),
        
        // https://opentelemetry.io/docs/reference/specification/trace/semantic_conventions/span-general/#network-transport-attributes
        @"net.host.connection.type": hostConnectionType(),
    };
}
