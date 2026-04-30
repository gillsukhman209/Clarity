//
//  TimeWheelsPicker.swift
//  Clarity
//
//  Custom wheel-style time picker. Two snapping vertical scroll columns —
//  hours (1–12) and minutes (00–59) — with the centered value highlighted
//  in the accent color and rendered larger. AM/PM segmented control
//  underneath. Same UI on iOS and macOS.
//
//  Why custom: the native macOS DatePicker variants are either ugly
//  (`.stepperField` / `.field`) or open a tiny clock-face popover that's
//  confusing to interact with (`.compact` for time). This is one
//  consistent, obviously-interactive control.
//

import SwiftUI

struct TimeWheelsPicker: View {
    @Binding var date: Date

    @State private var hour12: Int = 12
    @State private var minute: Int = 0
    @State private var isPM: Bool = false
    @State private var didLoadInitial: Bool = false

    private let rowHeight: CGFloat = 38
    private let visibleRows: Int = 5

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 6) {
                wheel(values: Array(1...12), selection: $hour12)
                Text(":")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 4)
                wheel(values: Array(0..<60), selection: $minute, format: { String(format: "%02d", $0) })
            }

            amPmSegmented
        }
        .padding(20)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.background)
        )
        .onAppear {
            guard !didLoadInitial else { return }
            syncFromDate()
            didLoadInitial = true
        }
        .onChange(of: hour12)  { _, _ in syncToDate() }
        .onChange(of: minute)  { _, _ in syncToDate() }
        .onChange(of: isPM)    { _, _ in syncToDate() }
    }

    // MARK: - Wheel column

    private func wheel(
        values: [Int],
        selection: Binding<Int>,
        format: @escaping (Int) -> String = { String($0) }
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Top spacer so the first item can center
                    Color.clear.frame(height: rowHeight * 2)
                    ForEach(values, id: \.self) { v in
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) {
                                selection.wrappedValue = v
                                proxy.scrollTo(v, anchor: .center)
                            }
                        } label: {
                            Text(format(v))
                                .font(.system(
                                    size: selection.wrappedValue == v ? 24 : 18,
                                    weight: selection.wrappedValue == v ? .bold : .regular,
                                    design: .rounded
                                ))
                                .foregroundStyle(selection.wrappedValue == v
                                                 ? AppColors.accent
                                                 : AppColors.textSecondary.opacity(0.55))
                                .frame(maxWidth: .infinity)
                                .frame(height: rowHeight)
                        }
                        .buttonStyle(.plain)
                        .id(v)
                    }
                    Color.clear.frame(height: rowHeight * 2)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding(
                get: { Optional(selection.wrappedValue) },
                set: { new in
                    if let new, new != selection.wrappedValue {
                        selection.wrappedValue = new
                    }
                }
            ))
            .frame(height: rowHeight * Double(visibleRows))
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black, location: 0.30),
                    .init(color: .black, location: 0.70),
                    .init(color: .clear, location: 1.00)
                ], startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                // Soft selection pill in the center row so the user can see
                // exactly which value is "selected".
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.accent.opacity(0.10))
                    .frame(height: rowHeight)
                    .allowsHitTesting(false)
                    .padding(.horizontal, 4)
            )
            .onAppear {
                // Wait one tick for layout, then center on the current value.
                DispatchQueue.main.async {
                    proxy.scrollTo(selection.wrappedValue, anchor: .center)
                }
            }
        }
    }

    // MARK: - AM/PM toggle

    private var amPmSegmented: some View {
        HStack(spacing: 0) {
            amPmButton("AM", on: !isPM) { isPM = false }
            amPmButton("PM", on: isPM)  { isPM = true  }
        }
        .padding(3)
        .background(Capsule(style: .continuous).fill(AppColors.surface))
        .overlay(Capsule(style: .continuous).stroke(AppColors.border, lineWidth: 1))
    }

    private func amPmButton(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(on ? .white : AppColors.textSecondary)
                .frame(width: 60)
                .padding(.vertical, 7)
                .background(Capsule(style: .continuous).fill(on ? AppColors.accent : Color.clear))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date <-> wheel state sync

    private func syncFromDate() {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        isPM = h >= 12
        let twelve = h % 12
        hour12 = twelve == 0 ? 12 : twelve
        minute = m
    }

    private func syncToDate() {
        let cal = Calendar.current
        var h24 = hour12 % 12
        if isPM { h24 += 12 }
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = h24
        comps.minute = minute
        comps.second = 0
        if let d = cal.date(from: comps) {
            date = d
        }
    }
}
