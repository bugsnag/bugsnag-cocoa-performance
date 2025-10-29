//
//  JSON.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

namespace bugsnag {

class JSON {
public:
    static NSDictionary *dataToDictionary(NSData *json, NSError **error) noexcept;
    static NSData *dictionaryToData(NSDictionary *dict, NSError **error) noexcept;
    static NSError *dictionaryToFile(NSString *path, NSDictionary *dict) noexcept;
    static NSDictionary *fileToDictionary(NSString *path, NSError **error) noexcept;
};

}
