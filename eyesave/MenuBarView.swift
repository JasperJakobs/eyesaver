//
//  MenuBarView.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import SwiftUI

// MARK: - Weekly Chart

struct WeeklyChartView: View {
    let stats: [EyeStrainTimer.DayStat]

    private var maxCount: Int {
        max(stats.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This Week")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(stats) { stat in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                stat.label == "Today"
                                    ? AnyShapeStyle(.linearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    ))
                                    : AnyShapeStyle(.primary.opacity(0.15))
                            )
                            .frame(
                                width: 24,
                                height: max(4, CGFloat(stat.count) / CGFloat(maxCount) * 40)
                            )

                        // Day label
                        Text(stat.label)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(stat.label == "Today" ? .primary : .tertiary)
                            .lineLimit(1)

                        // Count
                        if stat.count > 0 {
                            Text("\(stat.count)")
                                .font(.system(size: 8, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(stat.label == "Today" ? .cyan : .secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Menu Bar View

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
                        HStack(spacing: 6) {
                            Text(statusLabel)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            if timer.pomodoroMode {
                                Text("POMO")
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(
                                        Capsule().fill(.red.opacity(0.7))
                                    )
                            }
                        }

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
                                        colors: timer.pomodoroMode ? [.red, .orange] : [.blue, .cyan],
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

            // Break streak
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 11))
                Text("\(timer.breaksCompletedToday) break\(timer.breaksCompletedToday == 1 ? "" : "s") today")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                if timer.pomodoroMode {
                    Spacer()
                    Text("Session \(timer.pomodoroSessionCount % 4 + 1)/4")
                        .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 8)

            // Weekly chart
            WeeklyChartView(stats: timer.weeklyBreaks)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

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
            VStack(spacing: 8) {
                if !timer.pomodoroMode {
                    // Interval slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Interval")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(timer.intervalMinutes)) min")
                                .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                        Slider(value: $timer.intervalMinutes, in: 5...60, step: 5)
                            .controlSize(.small)
                    }

                    // Break duration slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Break")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(timer.breakDurationSeconds))s")
                                .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                        Slider(value: $timer.breakDurationSeconds, in: 10...60, step: 5)
                            .controlSize(.small)
                    }
                } else {
                    // Pomodoro info
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("25 min work / 5 min break")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text("15 min break every 4th session")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                }

                // Pomodoro toggle
                HStack {
                    Label("Pomodoro Mode", systemImage: "timer")
                        .font(.system(size: 13, design: .rounded))
                    Spacer()
                    Toggle("", isOn: $timer.pomodoroMode)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                }

                // Launch at login
                HStack {
                    Label("Launch at Login", systemImage: "sunrise")
                        .font(.system(size: 13, design: .rounded))
                    Spacer()
                    Toggle("", isOn: $timer.launchAtLogin)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Shortcut hint
            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text("⌘⇧E to skip break")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

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
        CGFloat(timer.secondsRemaining) / CGFloat(timer.intervalMinutes * 60)
    }

    private var statusLabel: String {
        if timer.isPaused { return "Paused" }
        if timer.isOnBreak { return "Break" }
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
