//
//  AutoInstrumentSwiftUIDeferredScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 27.12.23.
//

import SwiftUI
import BugsnagPerformance
import BugsnagPerformanceSwiftUI

@objcMembers
class AutoInstrumentSwiftUIDeferredScenario: Scenario {
    var view = AutoInstrumentSwiftUIDeferredScenario_View(model: AutoInstrumentSwiftUIDeferredModel())

    override func run() {
        if #available(iOS 13.0.0, *) {
            UIApplication.shared.windows[0].rootViewController!.present(
                UIHostingController(rootView: view), animated: true)
        } else {
            fatalError("SwiftUI is not available on this version of iOS")
        }
    }

    func toggleHideText1() {
        self.view.toggleHideText1()
    }

    func toggleEndSpanDefer() {
        self.view.toggleEndSpanDefer()
    }
}

class AutoInstrumentSwiftUIDeferredModel: ObservableObject {
    @Published var shouldShowText1: Bool = true
    @Published var shouldDeferEndSpan: Bool = true

    func toggleHideText1() {
        shouldShowText1.toggle()
    }

    func toggleEndSpanDefer() {
        shouldDeferEndSpan.toggle()
    }
}

@available(iOS 13.0.0, *)
struct AutoInstrumentSwiftUIDeferredScenario_View: View {
    @ObservedObject var model : AutoInstrumentSwiftUIDeferredModel

    func toggleHideText1() {
        DispatchQueue.main.async { self.model.toggleHideText1() }
    }

    func toggleEndSpanDefer() {
        DispatchQueue.main.async { self.model.toggleEndSpanDefer() }
    }

    var body: some View {
        VStack {
            if model.shouldShowText1 {
                Text("Text 1")
                .bugsnagTraced("text1")
                .bugsnagDeferEndUntilViewDisappears()
            }
        }
        .bugsnagTraced("vstack1")
        .bugsnagDeferEndUntil {
            return !model.shouldDeferEndSpan
        }
    }
}
