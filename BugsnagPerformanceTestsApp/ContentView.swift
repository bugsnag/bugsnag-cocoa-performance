//
//  ContentView.swift
//  BugsnagPerformanceTestsApp
//
//  Created by Robert B on 04/04/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
