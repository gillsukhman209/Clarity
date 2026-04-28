//
//  DatePickerSheet.swift
//  Clarity
//
//  Graphical calendar picker, used by the day-nav on both platforms.
//  Tapping the date label in the top bar opens this; tapping a day jumps
//  to it without needing to step through the chevrons.
//

import SwiftUI

struct DatePickerSheet: View {
    @Binding var date: Date
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Jump to date")
                    .font(AppTypography.titleSmall)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Button("Today") {
                    date = Calendar.current.startOfDay(for: Date())
                }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.accent)
                .buttonStyle(.plain)
            }

            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(AppColors.accent)

            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Text("Done")
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(Capsule(style: .continuous).fill(AppColors.accent))
                }
                .buttonStyle(PressableStyle(pressedScale: 0.98))
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.background)
        .frame(minWidth: 360, minHeight: 440)
        .onChange(of: date) { _, newValue in
            // Keep `currentDate` aligned to start-of-day so filtering works.
            let normalized = Calendar.current.startOfDay(for: newValue)
            if normalized != date {
                date = normalized
            }
        }
    }
}
