//
//  ContentView.swift
//  Clarity
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var store: TaskStore?

    var body: some View {
        Group {
            if let store {
                rootView
                    .environment(store)
            } else {
                AppColors.background.ignoresSafeArea()
            }
        }
        .preferredColorScheme(.light)
        .task {
            if store == nil {
                store = TaskStore(context: context)
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if os(iOS)
        RootTabView()
        #else
        MacRootView()
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskRecord.self, SubtaskRecord.self], inMemory: true)
}
