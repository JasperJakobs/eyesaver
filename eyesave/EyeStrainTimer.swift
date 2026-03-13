//
//  EyeStrainTimer.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import SwiftUI
import ServiceManagement

@Observable
class EyeStrainTimer {
    var isPaused = false
    var isOnBreak = false
    var secondsRemaining: Int = 20 * 60
    var breakSecondsRemaining: Int = 20
    var launchAtLogin: Bool = false {
        didSet { updateLaunchAtLogin() }
    }

    private var intervalTask: Task<Void, Never>?
    private var breakTask: Task<Void, Never>?
    private let windowController = BreakWindowController()

    var menuBarText: String {
        if isPaused { return "Paused" }
        if isOnBreak { return "\(breakSecondsRemaining)s" }
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    init() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
        startInterval()
    }

    func startInterval() {
        secondsRemaining = 20 * 60
        intervalTask?.cancel()
        intervalTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if secondsRemaining > 0 {
                    withAnimation {
                        secondsRemaining -= 1
                    }
                } else {
                    triggerBreak()
                    return
                }
            }
        }
    }

    func triggerBreak() {
        intervalTask?.cancel()
        isOnBreak = true
        breakSecondsRemaining = 20
        windowController.show(timer: self)

        breakTask?.cancel()
        breakTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if breakSecondsRemaining > 1 {
                    withAnimation {
                        breakSecondsRemaining -= 1
                    }
                } else {
                    endBreak()
                    return
                }
            }
        }
    }

    func endBreak() {
        breakTask?.cancel()
        isOnBreak = false
        windowController.dismiss()
        startInterval()
    }

    func skipBreak() {
        endBreak()
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    func pause() {
        isPaused = true
        intervalTask?.cancel()
        if isOnBreak {
            breakTask?.cancel()
            isOnBreak = false
            windowController.dismiss()
        }
    }

    func resume() {
        isPaused = false
        startInterval()
    }

    func testBreak() {
        intervalTask?.cancel()
        triggerBreak()
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // May fail during development without proper signing
        }
    }
}
