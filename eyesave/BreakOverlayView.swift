//
//  BreakOverlayView.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import SwiftUI

struct BreakOverlayView: View {
    var timer: EyeStrainTimer
    @State private var ringProgress: Double = 1.0
    @State private var pulseGlow = false
    @State private var appeared = false

    private let ringGradient = LinearGradient(
        colors: [.blue, .cyan, .mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 24) {
            Text("Look Away")
                .font(.title2.weight(.semibold))

            // Countdown ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: 5)

                // Glow layer
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(ringGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 12)
                    .opacity(pulseGlow ? 0.9 : 0.35)

                // Main progress ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(ringGradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Countdown number
                Text("\(timer.breakSecondsRemaining)")
                    .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(width: 150, height: 150)

            Text("Rest your eyes for a moment")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Skip button
            Button {
                timer.skipBreak()
            } label: {
                Text("Skip")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 36)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                appeared = true
            }
            withAnimation(.linear(duration: 20)) {
                ringProgress = 0
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
    }
}
