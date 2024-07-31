//
//  SwiftErrorGenerator.swift
//  Fixture
//
//  Created by Karl Stenerud on 26.07.24.
//

import Foundation

enum MySwiftError: Error {
    case oops
}

@objc
@objcMembers
class SwiftErrorGenerator: NSObject {

    func throwSwiftError() throws {
        throw MySwiftError.oops
    }
}
