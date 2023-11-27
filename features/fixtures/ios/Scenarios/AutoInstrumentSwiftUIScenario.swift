//
//  AutoInstrumentSwiftUIScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 27.11.23.
//

import SwiftUI
import BugsnagPerformance
import BugsnagPerformanceSwiftUI

@objcMembers
class AutoInstrumentSwiftUIScenario: Scenario {
    override func run() {
        if #available(iOS 13.0.0, *) {
            UIApplication.shared.windows[0].rootViewController!.present(
                UIHostingController(rootView: AutoInstrumentSwiftUIScenario_View()), animated: true)
        } else {
            fatalError("SwiftUI is not available on this version of iOS")
        }
    }
}

@available(iOS 13.0.0, *)
struct AutoInstrumentSwiftUIScenario_View: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .bugsnagTraced("My text view")
        }
        .padding()
    }
}
