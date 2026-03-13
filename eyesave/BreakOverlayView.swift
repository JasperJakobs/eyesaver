//
//  BreakOverlayView.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import SwiftUI

struct BreakOverlayView: View {
    var timer: EyeStrainTimer
    @State private var borderProgress: Double = 1.0
    @State private var pulseGlow = false
    @State private var appeared = false
    @State private var eyeBreathe = false

    private let borderGradient = AngularGradient(
        stops: [
            .init(color: .cyan, location: 0.0),
            .init(color: .blue, location: 0.25),
            .init(color: .mint, location: 0.5),
            .init(color: .cyan, location: 0.75),
            .init(color: .blue, location: 1.0),
        ],
        center: .center
    )

    var body: some View {
        ZStack {
            // Deep glow behind the pill
            Capsule()
                .fill(.cyan.opacity(pulseGlow ? 0.12 : 0.04))
                .blur(radius: 30)

            // Glow border (blurred)
            Capsule()
                .trim(from: 0, to: borderProgress)
                .stroke(borderGradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .blur(radius: 12)
                .opacity(pulseGlow ? 1.0 : 0.4)
                .padding(-4)

            // Crisp border progress
            Capsule()
                .trim(from: 0, to: borderProgress)
                .stroke(borderGradient, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            // Track border (dim)
            Capsule()
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)

            // Content
            HStack(spacing: 0) {
                // Eye icon (left)
                ZStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.cyan)
                        .blur(radius: 8)
                        .opacity(eyeBreathe ? 0.8 : 0.2)

                    Image(systemName: "eye.fill")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(eyeBreathe ? 1.08 : 0.95)
                }
                .frame(width: 24)

                Spacer()

                // Countdown (center)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(timer.breakSecondsRemaining)")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(countsDown: true))

                    Text("s")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                }

                Spacer()

                // Skip button (right)
                Button {
                    timer.skipBreak()
                } label: {
                    Text("Skip")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.07))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
        }
        .frame(width: 300, height: 62)
        .background {
            Capsule()
                .fill(.black.opacity(0.55))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        }
        .clipShape(Capsule())
        .environment(\.colorScheme, .dark)
        .scaleEffect(appeared ? 1.0 : 0.7)
        .offset(y: appeared ? 0 : -12)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                appeared = true
            }
            withAnimation(.linear(duration: 20)) {
                borderProgress = 0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                eyeBreathe = true
            }
        }
    }
}
