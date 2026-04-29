//
//  PhaseGlyphs.swift
//  Clarity
//
//  Custom glyph shapes used in the phase-timeline badges, since no SF Symbol
//  matches the mockup's Saturn (planet + ring) or alarm-clock-with-ears.
//

import SwiftUI

/// A small Saturn glyph: a circle with a tilted ellipse drawn through it.
/// Used as the icon for the Focus phase.
struct SaturnGlyph: View {
    var size: CGFloat = 16
    var color: Color = .white

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(color, lineWidth: max(1, size * 0.06))
                .frame(width: size * 1.2, height: size * 0.32)
                .rotationEffect(.degrees(-18))
            Circle()
                .fill(color)
                .frame(width: size * 0.62, height: size * 0.62)
        }
        .frame(width: size, height: size)
    }
}

/// A small alarm-clock glyph: circular face with two ear-bells on top.
/// Used for Short Break and Long Break.
struct AlarmGlyph: View {
    var size: CGFloat = 16
    var color: Color = .white

    var body: some View {
        ZStack {
            // Two ear-bells
            HStack(spacing: size * 0.50) {
                Circle().fill(color).frame(width: size * 0.18, height: size * 0.18)
                Circle().fill(color).frame(width: size * 0.18, height: size * 0.18)
            }
            .offset(y: -size * 0.42)

            // Body
            Circle()
                .stroke(color, lineWidth: max(1, size * 0.08))
                .frame(width: size * 0.78, height: size * 0.78)

            // Hour + minute hand at ~10:10
            Path { p in
                p.move(to: CGPoint(x: size * 0.5, y: size * 0.5))
                p.addLine(to: CGPoint(x: size * 0.32, y: size * 0.40))
                p.move(to: CGPoint(x: size * 0.5, y: size * 0.5))
                p.addLine(to: CGPoint(x: size * 0.62, y: size * 0.30))
            }
            .stroke(color, style: StrokeStyle(lineWidth: max(1, size * 0.06), lineCap: .round))
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}
