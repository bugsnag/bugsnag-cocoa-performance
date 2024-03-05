//
//  SomeView.swift
//  Example
//
//  Created by Nick Dowell on 11/10/2022.
//

import BugsnagPerformance
import BugsnagPerformanceSwift
import SwiftUI

@available(iOS 13.0.0, *)
struct SomeView: View {
    @State var data: Data?
    @State var deferringViewLoadSpan = true

    var body: some View {

        // Fake a background data load.
        // On iOS 15+ you'd use a .task()
        defer {
            DispatchQueue.global().async {
                data = Data()
            }
        }

        return VStack {
            if data == nil {
                // .bugsnagDeferEndUntilViewDisappears() will hold the current
                // view load span open until this Text view disappears.
                //
                // When this Text view disappears, its defer is resolved.
                // That would in theory leave the view load span free to end,
                // but there are still other defers to resolve!
                Text("SwiftUI is loading")
                .bugsnagTraced("loading")
                .bugsnagDeferEndUntilViewDisappears()
            } else {
                Text("Hello from SwiftUI 🙃")
                .bugsnagTraced("loaded")

                if deferringViewLoadSpan {
                    // Defer the view load span end until this button disappears.
                    Button("Stop deferring the view load span") {
                        deferringViewLoadSpan = false
                    }
                    .bugsnagDeferEndUntilViewDisappears()
                }
            }
        }
        .bugsnagDeferEndUntil {
            // Defer the view load span end until this function returns a true value.
            //
            // This is technically redundant since the above button is deferring the
            // view load span based on the same @State value (deferringViewLoadSpan).
            return !deferringViewLoadSpan
        }
    }
}

@available(iOS 13.0.0, *)
struct SomeView_Previews: PreviewProvider {
    static var previews: some View {
        SomeView()
    }
}
