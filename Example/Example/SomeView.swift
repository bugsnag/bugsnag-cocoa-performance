//
//  SomeView.swift
//  Example
//
//  Created by Nick Dowell on 11/10/2022.
//

import BugsnagPerformance
import SwiftUI

@available(iOS 13.0.0, *)
struct SomeView: View {
    var body: some View {
        let span = BugsnagPerformance.startViewLoadSpan(
            name: "SomeView", viewType: .swiftUI) 
        Text("Hello from SwiftUI 🙃")
            .onAppear {
                span.end()
            }
    }
}

@available(iOS 13.0.0, *)
struct SomeView_Previews: PreviewProvider {
    static var previews: some View {
        SomeView()
    }
}
