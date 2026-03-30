// FilesystemSwizzle.swift
// Pure-Swift swizzle + Maze Runner fixture helpers

import Foundation
import ObjectiveC
import UIKit

@objcMembers
class FilesystemSwizzle: NSObject {
    static let shared = FilesystemSwizzle()

    enum Mode: String {
        case ok = "ok"
        case alwaysFail = "always_fail"
        case failOnce = "fail_once"
    }

    private override init() {}

    // MARK: - Installer
    @objc static func installSwizzle() {
        struct Guard { static var didInstall = false }
        if Guard.didInstall { return }
        Guard.didInstall = true

        guard let cls = objc_getClass("NSFileManager") as? AnyClass else {
            NSLog("FilesystemSwizzle: NSFileManager not found")
            return
        }
        let sel = NSSelectorFromString("createDirectoryAtURL:withIntermediateDirectories:attributes:error:")
        guard let method = class_getInstanceMethod(cls, sel) else {
            NSLog("FilesystemSwizzle: selector not found")
            return
        }

        let originalIMP = method_getImplementation(method)
        typealias OrigCFunc = @convention(c) (AnyObject, Selector, NSURL?, ObjCBool, NSDictionary?, UnsafeMutablePointer<Unmanaged<NSError>?>?) -> ObjCBool
        let origFn = unsafeBitCast(originalIMP, to: OrigCFunc.self)

        // replacement block
        let block: @convention(block) (AnyObject, NSURL?, ObjCBool, NSDictionary?, UnsafeMutablePointer<Unmanaged<NSError>?>?) -> ObjCBool = { (_self, url, createIntermediates, attrs, errPtr) in
            let defaults = UserDefaults.standard
            let mode = defaults.string(forKey: "maze_swizzle_mode") ?? "ok"
            var remaining = defaults.integer(forKey: "maze_swizzle_remaining_attempts")

            let attempts = defaults.integer(forKey: "maze_create_attempts") + 1
            defaults.set(attempts, forKey: "maze_create_attempts")

            if mode == "always_fail" {
                defaults.set(true, forKey: "maze_storage_disabled")
                defaults.synchronize()
                return ObjCBool(false)
            }

            if mode == "fail_once" && remaining > 0 {
                remaining -= 1
                defaults.set(remaining, forKey: "maze_swizzle_remaining_attempts")
                defaults.set(true, forKey: "maze_storage_disabled")
                defaults.synchronize()
                return ObjCBool(false)
            }

            // call original implementation
            let res = origFn(_self, sel, url, createIntermediates, attrs, errPtr)
            defaults.set(false, forKey: "maze_storage_disabled")
            defaults.synchronize()
            return res
        }

        let imp = imp_implementationWithBlock(block as Any)
        method_setImplementation(method, imp)
        NSLog("FilesystemSwizzle: pure-Swift swizzle installed")
    }

    // MARK: - Helpers used by test steps
    @objc func setMode(_ modeStr: String, attempts: NSNumber?) {
        let defaults = UserDefaults.standard
        defaults.set(modeStr, forKey: "maze_swizzle_mode")
        defaults.set(attempts?.intValue ?? 0, forKey: "maze_swizzle_remaining_attempts")
        defaults.set(0, forKey: "maze_create_attempts")
        defaults.set(false, forKey: "maze_storage_disabled")
        defaults.set([], forKey: "maze_stored_files")
        defaults.synchronize()
    }

    @objc func performStartupDirectoryCreation() {
        let fm = FileManager.default
        do {
            let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dir = docs.appendingPathComponent("BugsnagTests")
            try fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("FilesystemSwizzle: startup createDirectory failed: \(error)")
        }
    }

    @objc func requestWrite(_ filename: String, payload: String) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "maze_storage_disabled") {
            NSLog("FilesystemSwizzle: storage disabled, skipping write for \(filename)")
            return
        }

        let fm = FileManager.default
        do {
            let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dir = docs.appendingPathComponent("BugsnagTests")
            if !fm.fileExists(atPath: dir.path) {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            }
            let fileUrl = dir.appendingPathComponent(filename)
            try payload.data(using: .utf8)?.write(to: fileUrl)
            var stored = defaults.stringArray(forKey: "maze_stored_files") ?? []
            stored.append(filename)
            defaults.set(stored, forKey: "maze_stored_files")
            defaults.synchronize()
        } catch {
            NSLog("FilesystemSwizzle: write failed: \(error)")
            defaults.set(true, forKey: "maze_storage_disabled")
            defaults.synchronize()
        }
    }

    @objc func getStatus() -> [String: Any] {
        let defaults = UserDefaults.standard
        let storageDisabled = defaults.bool(forKey: "maze_storage_disabled")
        let stored = defaults.stringArray(forKey: "maze_stored_files") ?? []
        let attempts = defaults.integer(forKey: "maze_create_attempts")
        return ["storage_disabled": storageDisabled, "stored_files": stored, "create_attempts": attempts]
    }
}

// Install swizzle at module load so no other files need modification
private let _filesystem_swizzle_installer: Void = {
    FilesystemSwizzle.installSwizzle()
}()

// Convenience Scenario extension so Maze Runner can invoke these methods via existing generic steps
extension Scenario {
    @objc func maze_set_swizzle_mode(_ args: String) {
        if let data = args.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            let mode = dict["mode"] as? String ?? "ok"
            let attempts = dict["attempts"] as? Int ?? 0
            FilesystemSwizzle.shared.setMode(mode, attempts: NSNumber(value: attempts))
        }
    }

    @objc func maze_perform_startup_creation() {
        FilesystemSwizzle.shared.performStartupDirectoryCreation()
    }

    @objc func maze_request_write(_ arg: String) {
        // Accept either JSON {filename,payload} or plain filename (payload from defaults)
        var filename = arg
        var payload = ""
        if let data = arg.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let fn = dict["filename"] as? String {
            filename = fn
            payload = dict["payload"] as? String ?? ""
        } else {
            payload = UserDefaults.standard.string(forKey: "maze_payload_\(arg)") ?? ""
        }
        FilesystemSwizzle.shared.requestWrite(filename, payload: payload)
    }

    @objc func maze_get_status() -> String {
        let status = FilesystemSwizzle.shared.getStatus()
        if let data = try? JSONSerialization.data(withJSONObject: status, options: []) {
            return String(data: data, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }
}
