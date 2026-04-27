//
//  ContentView.swift
//  Clarity
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
        RootTabView()
            .preferredColorScheme(.light)
        #else
        MacRootView()
            .preferredColorScheme(.light)
        #endif
    }
}

#Preview {
    ContentView()
}
