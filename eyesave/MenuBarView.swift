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
        VStack(spacing: 12) {
            // Status header
            HStack(spacing: 12) {
                Image(systemName: timer.isOnBreak ? "eye.slash.circle.fill" : "eye.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse, isActive: !timer.isPaused && !timer.isOnBreak)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !timer.isPaused {
                        Text(timer.menuBarText)
                            .font(.title3.bold().monospacedDigit())
                            .contentTransition(.numericText(countsDown: true))
                    }
                }

                Spacer()
            }
            .padding(.bottom, 4)

            Divider()

            // Pause / Resume
            Button {
                timer.togglePause()
            } label: {
                Label(
                    timer.isPaused ? "Resume" : "Pause",
                    systemImage: timer.isPaused ? "play.fill" : "pause.fill"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Test Break
            Button {
                timer.testBreak()
            } label: {
                Label("Test Break", systemImage: "eye.trianglebadge.exclamationmark")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            // Launch at Login
            Toggle(isOn: $timer.launchAtLogin) {
                Label("Launch at Login", systemImage: "sunrise")
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Divider()

            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Eyesave", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 260)
    }

    private var statusLabel: String {
        if timer.isPaused { return "Paused" }
        if timer.isOnBreak { return "Break in progress" }
        return "Next break in"
    }
}
