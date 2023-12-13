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
    public var isFirstBodyThisCycle = true
    public var parentViewLoadSpan: BugsnagPerformanceSpan? = nil
    public var unresolvedDeferCount = 0
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

    /**
     * Trace this view through Bugsnag.
     * If viewName is not specified, one will be generated based on the struct's class.
     */
    func bugsnagTraced(_ viewName: String? = nil) -> some View {
        return BugsnagTracedView(viewName) {
            return self
        }
    }

    /**
     * Defer ending the overarching view load span until the supplied function returns true during a body build cycle.
     * The view load span will not be ended until ALL deferred-end conditions are true.
     */
    func bugsnagDeferEndUntil(deferUntil: @escaping ()->(Bool)) -> some View {
        return BugsnagDeferredTraceEndView(deferUntil: deferUntil) {self}
    }

    /**
     * Defer ending the overarching view load span until this view disappears from the view hierarchy.
     * The view load span will not be ended until ALL deferred-end conditions are true.
     */
    func bugsnagDeferEndUntilViewDisappears() -> some View {
        return self.bugsnagDeferEndUntil {
            return false
        }
    }
}

private static let defaultViewName = {
    let viewName = String(describing: content)
    if let angleBracketIndex = viewName.firstIndex(of: "<") {
        return String(viewName[viewName.startIndex ..< angleBracketIndex])
    }
    return viewName
}()

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
public struct BugsnagDeferredTraceEndView<Content: View>: View {
    @Environment(\.keyBSGViewContext) private var bsgViewContext: BugsnagViewContext

    private let content: () -> Content
    private let deferUntilCondition: ()->(Bool)

    public init(deferUntil: @escaping ()->(Bool), content: @escaping () -> Content) {
        self.content = content
        self.deferUntilCondition = deferUntil
    }

    public var body: some View {
        if !deferUntilCondition() {
            bsgViewContext.unresolvedDeferCount += 1
        }

        // We're not generating our own content; merely passing through the content
        // of the body we wrapped. The rendered scene will not contain any Bugsnag views.
        return content()
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6.0, *)
public struct BugsnagTracedView<Content: View>: View {
    @Environment(\.keyBSGViewContext) private var bsgViewContext: BugsnagViewContext

    private let content: () -> Content
    private let name: String

    public init(_ viewName: String? = nil, content: @escaping () -> Content) {
        self.content = content
        self.name = viewName ?? defaultViewName
    }

    public var body: some View {
        var parentViewLoadSpan = bsgViewContext.parentViewLoadSpan

        if bsgViewContext.isFirstBodyThisCycle {
            bsgViewContext.isFirstBodyThisCycle = false

            if parentViewLoadSpan == nil {
                let opts = BugsnagPerformanceSpanOptions()
                opts.setParentContext(nil)
                let thisViewLoadSpan = BugsnagPerformance.startViewLoadSpan(name: name, viewType: BugsnagPerformanceViewType.swiftUI, options: opts)
                parentViewLoadSpan = thisViewLoadSpan
                bsgViewContext.parentViewLoadSpan = thisViewLoadSpan
            }

            DispatchQueue.main.async {
                if bsgViewContext.unresolvedDeferCount == 0 {
                    bsgViewContext.parentViewLoadSpan?.end()
                    bsgViewContext.parentViewLoadSpan = nil
                }
                bsgViewContext.unresolvedDeferCount = 0
                bsgViewContext.isFirstBodyThisCycle = true
            }
        }

        let opts = BugsnagPerformanceSpanOptions()
        opts.setParentContext(parentViewLoadSpan)
        // We are actually recording a point here, not measuring a duration.
        BugsnagPerformance.startViewLoadPhaseSpan(name: name, phase: "body", parentContext: parentViewLoadSpan!).end()

        // We're not generating our own content; merely passing through the content
        // of the body we wrapped. The rendered scene will not contain any Bugsnag views.
        return content()
    }
}
