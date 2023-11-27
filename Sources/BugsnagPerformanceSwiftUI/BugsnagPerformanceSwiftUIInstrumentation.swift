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
public extension View {
    func bugsnagTraced(_ viewName: String? = nil) -> some View {
        return BugsnagTracedView(viewName) {
            return self
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
public struct BugsnagTracedView<Content: View>: View {
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
        let parentSpan = BugsnagPerformance.startViewLoadSpan(name: name, viewType: BugsnagPerformanceViewType.swiftUI)
        let viewLoadSpan = BugsnagPerformance.startViewLoadPhaseSpan(name: name, phase: "loadView", parentContext: parentSpan)

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            var viewAppearSpan: BugsnagPerformanceSpan? = nil
            content()
            .onAppear {
                viewLoadSpan.end()
                viewAppearSpan = BugsnagPerformance.startViewLoadPhaseSpan(name: name, phase: "View appearing", parentContext: parentSpan)
            }
            .task(priority: .background) {
                viewAppearSpan?.end()
                parentSpan.end()
            }
        } else {
            content()
            .onAppear {
                viewLoadSpan.end()
                parentSpan.end()
            }

        }
    }
}
