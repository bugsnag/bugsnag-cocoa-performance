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
    var view = AutoInstrumentSwiftUIScenario_View(model: AutoInstrumentSwiftUIModel())

    override func run() {
        if #available(iOS 13.0.0, *) {
            UIApplication.shared.windows[0].rootViewController!.present(
                UIHostingController(rootView: view), animated: true)
        } else {
            fatalError("SwiftUI is not available on this version of iOS")
        }
    }
    
    func switchView() {
        self.view.switchView()
    }
}

class AutoInstrumentSwiftUIModel: ObservableObject {
    @Published var shouldSwitchViews: Bool = false
    
    func switchViews() {
        shouldSwitchViews.toggle()
    }
}

@available(iOS 13.0.0, *)
struct AutoInstrumentSwiftUIScenario_View: View {
    @ObservedObject var model : AutoInstrumentSwiftUIModel

    func switchView() {
        DispatchQueue.main.async { self.model.switchViews() }
    }

    var body: some View {
        if !model.shouldSwitchViews {
            return AnyView(VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .bugsnagTraced("My Image view")
            }
            .bugsnagTraced("My VStack view")
            .padding())
        } else {
            return AnyView(Text("Switched").bugsnagTraced("Text"))
        }
    }
}
