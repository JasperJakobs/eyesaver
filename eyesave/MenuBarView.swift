//
//  MenuBarView.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import SwiftUI

struct MenuBarView: View {
    @Bindable var timer: EyeStrainTimer

    var body: some View {
        VStack(spacing: 0) {
            // Status header
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Image(systemName: timer.isOnBreak ? "eye.slash.circle.fill" : "eye.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse, isActive: !timer.isPaused && !timer.isOnBreak)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusLabel)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        if !timer.isPaused {
                            Text(timer.menuBarText)
                                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                                .contentTransition(.numericText(countsDown: true))
                        }
                    }

                    Spacer()
                }

                // Progress bar
                if !timer.isPaused && !timer.isOnBreak {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.primary.opacity(0.08))
                                .frame(height: 3)
                            Capsule()
                                .fill(
                                    .linearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * intervalProgress, height: 3)
                                .animation(.linear(duration: 1), value: timer.secondsRemaining)
                        }
                    }
                    .frame(height: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 8)

            // Actions
            VStack(spacing: 2) {
                menuButton(
                    title: timer.isPaused ? "Resume" : "Pause",
                    icon: timer.isPaused ? "play.fill" : "pause.fill"
                ) {
                    timer.togglePause()
                }

                menuButton(
                    title: "Test Break",
                    icon: "eye.trianglebadge.exclamationmark"
                ) {
                    timer.testBreak()
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)

            Divider().padding(.horizontal, 8)

            // Settings
            HStack {
                Label("Launch at Login", systemImage: "sunrise")
                    .font(.system(size: 13, design: .rounded))
                Spacer()
                Toggle("", isOn: $timer.launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider().padding(.horizontal, 8)

            // Quit
            menuButton(title: "Quit Eyesave", icon: "xmark.circle") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .padding(.bottom, 4)
        }
        .frame(width: 280)
    }

    private var intervalProgress: CGFloat {
        CGFloat(timer.secondsRemaining) / CGFloat(20 * 60)
    }

    private var statusLabel: String {
        if timer.isPaused { return "Paused" }
        if timer.isOnBreak { return "Break in progress" }
        return "Next break in"
    }

    private func menuButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13, design: .rounded))
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
