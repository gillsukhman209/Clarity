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
        MacPlaceholderView()
            .preferredColorScheme(.light)
        #endif
    }
}

#if os(macOS)
private struct MacPlaceholderView: View {
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppColors.accent.opacity(0.7))
            Text("Clarity")
                .font(AppTypography.displayLarge)
                .foregroundStyle(AppColors.textPrimary)
            Text("macOS dashboard arrives in Phase 4.")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
#endif

#Preview {
    ContentView()
}
