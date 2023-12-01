//
//  BugsnagPerformanceSwiftUIInstrumentation.swift
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.11.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

import SwiftUI
import BugsnagPerformance

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
final class BugsnagViewContext: ObservableObject {
    public var firstViewLoadSpan: BugsnagPerformanceSpan? = nil
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
private struct BSGEnvironmentKey: EnvironmentKey {
    static let defaultValue: BugsnagViewContext = .init()
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
extension EnvironmentValues {
    var keyBSGViewContext: BugsnagViewContext {
        get { self[BSGEnvironmentKey.self] }
        set { self[BSGEnvironmentKey.self] = newValue }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
extension View {
    func bsgViewContext(_ bsgViewContext: BugsnagViewContext) -> some View {
        environment(\.keyBSGViewContext, bsgViewContext)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
public extension View {
    func bugsnagTraced(_ viewName: String? = nil) -> some View {
        return BugsnagTracedView(viewName) {
            return self
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
public struct BugsnagTracedView<Content: View>: View {
    @Environment(\.keyBSGViewContext) private var bsgViewContext: BugsnagViewContext

    let content: () -> Content
    let name: String

    public init(_ viewName: String? = nil, content: @escaping () -> Content) {
        self.content = content
        self.name = viewName ?? BugsnagTracedView.getViewName(content: Content.self)
    }

    private static func getViewName(content: Any) -> String {
        let viewName = String(describing: content)
        if let angleBracketIndex = viewName.firstIndex(of: "<") {
            return String(viewName[viewName.startIndex ..< angleBracketIndex])
        }
        return viewName
    }

    public var body: some View {
        let firstViewLoadSpan = bsgViewContext.firstViewLoadSpan

        if firstViewLoadSpan == nil {
            let opts = BugsnagPerformanceSpanOptions()
            opts.setParentContext(nil)
            let thisViewLoadSpan = BugsnagPerformance.startViewLoadSpan(name: "\(name) (top-level view)", viewType: BugsnagPerformanceViewType.swiftUI, options: opts)
            bsgViewContext.firstViewLoadSpan = thisViewLoadSpan
            DispatchQueue.main.async {
                thisViewLoadSpan.end()
            }
        }

        let opts = BugsnagPerformanceSpanOptions()
        opts.setParentContext(firstViewLoadSpan)
        let thisViewLoadSpan = BugsnagPerformance.startViewLoadSpan(name: name, viewType: BugsnagPerformanceViewType.swiftUI, options: opts)
        defer {
            thisViewLoadSpan.end()
        }
        return content()
    }
}
