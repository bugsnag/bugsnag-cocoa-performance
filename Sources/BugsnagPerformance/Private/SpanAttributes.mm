//
//  SpanAttributes.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 03/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "SpanAttributes.h"

#import "Reachability.h"

#import <UIKit/UIKit.h>

using namespace bugsnag;

static bool appInForeground() noexcept {
    auto inner = [](){
        return UIApplication.sharedApplication.applicationState != UIApplicationStateBackground;
    };
    
    if ([NSThread isMainThread]) {
        return inner();
    }
    
    bool __block result;
    dispatch_sync(dispatch_get_main_queue(), ^{
        result = inner();
    });
    return result;
}

static NSString *hostConnectionType() noexcept {
    switch (Reachability::get().getConnectivity()) {
        case bugsnag::Reachability::Unknown:    return @"unknown";
        case bugsnag::Reachability::None:       return @"unavailable";
        case bugsnag::Reachability::Cellular:   return @"cell";
        case bugsnag::Reachability::Wifi:       return @"wifi";
    }
}

NSDictionary *
SpanAttributes::get() noexcept {
    return @{
        @"bugsnag.app.in_foreground": appInForeground() ? @YES : @NO,
        
        // https://opentelemetry.io/docs/reference/specification/trace/semantic_conventions/span-general/#network-transport-attributes
        @"net.host.connection.type": hostConnectionType(),
    };
}
