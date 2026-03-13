//
//  EyeStrainTimer.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import SwiftUI
import ServiceManagement
import Carbon.HIToolbox

@Observable
class EyeStrainTimer {
    // MARK: - State

    var isPaused = false
    var isOnBreak = false
    var secondsRemaining: Int = 20 * 60
    var breakSecondsRemaining: Int = 20
    var breaksCompletedToday: Int = 0
    var isBlinking = false

    // MARK: - Weekly Stats

    var weeklyBreaks: [DayStat] = []

    struct DayStat: Identifiable {
        let id: String // date string
        let label: String // short day name
        let count: Int
    }

    // MARK: - Pomodoro Mode

    var pomodoroMode: Bool = false {
        didSet {
            UserDefaults.standard.set(pomodoroMode, forKey: "pomodoroMode")
            applyModeSettings()
        }
    }

    var pomodoroSessionCount: Int = 0 // tracks sessions for long break

    // MARK: - Settings

    var intervalMinutes: Double = 20 {
        didSet {
            if !isOnBreak && !isPaused {
                secondsRemaining = Int(intervalMinutes * 60)
            }
            UserDefaults.standard.set(intervalMinutes, forKey: "intervalMinutes")
        }
    }

    var breakDurationSeconds: Double = 20 {
        didSet {
            UserDefaults.standard.set(breakDurationSeconds, forKey: "breakDurationSeconds")
        }
    }

    var launchAtLogin: Bool = false {
        didSet { updateLaunchAtLogin() }
    }

    // MARK: - Private

    private var intervalTask: Task<Void, Never>?
    private var breakTask: Task<Void, Never>?
    private var blinkTask: Task<Void, Never>?
    private var sleepObserverTask: Task<Void, Never>?
    private var screenSharingTask: Task<Void, Never>?
    private let windowController = BreakWindowController()
    private var hotKeyRef: EventHotKeyRef?
    private var wasRunningBeforeSleep = false

    // Saved non-pomodoro values for restoring
    private var savedInterval: Double = 20
    private var savedBreak: Double = 20

    // MARK: - Computed

    var menuBarText: String {
        if isPaused { return "Paused" }
        if isOnBreak { return "\(breakSecondsRemaining)s" }
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    var breakProgress: Double {
        Double(breakSecondsRemaining) / breakDurationSeconds
    }

    // MARK: - Init

    init() {
        let savedInt = UserDefaults.standard.double(forKey: "intervalMinutes")
        if savedInt > 0 { intervalMinutes = savedInt }

        let savedBrk = UserDefaults.standard.double(forKey: "breakDurationSeconds")
        if savedBrk > 0 { breakDurationSeconds = savedBrk }

        pomodoroMode = UserDefaults.standard.bool(forKey: "pomodoroMode")

        savedInterval = intervalMinutes
        savedBreak = breakDurationSeconds

        loadTodayBreaks()
        loadWeeklyStats()

        launchAtLogin = SMAppService.mainApp.status == .enabled

        if pomodoroMode { applyModeSettings() }
        secondsRemaining = Int(intervalMinutes * 60)
        startInterval()
        startBlinkAnimation()
        observeSleepWake()
        observeScreenSharing()
        registerGlobalHotKey()
    }

    // MARK: - Pomodoro

    private func applyModeSettings() {
        if pomodoroMode {
            savedInterval = intervalMinutes
            savedBreak = breakDurationSeconds
            intervalMinutes = 25
            breakDurationSeconds = 5 * 60
            pomodoroSessionCount = 0
        } else {
            intervalMinutes = savedInterval > 0 ? savedInterval : 20
            breakDurationSeconds = savedBreak > 0 ? savedBreak : 20
            pomodoroSessionCount = 0
        }
        if !isOnBreak {
            secondsRemaining = Int(intervalMinutes * 60)
        }
    }

    // MARK: - Timer Control

    func startInterval() {
        secondsRemaining = Int(intervalMinutes * 60)
        intervalTask?.cancel()
        intervalTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if secondsRemaining > 0 {
                    withAnimation { secondsRemaining -= 1 }
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

        // In pomodoro mode, every 4th session is a long break (15 min)
        if pomodoroMode {
            pomodoroSessionCount += 1
            if pomodoroSessionCount % 4 == 0 {
                breakSecondsRemaining = 15 * 60
            } else {
                breakSecondsRemaining = Int(breakDurationSeconds)
            }
        } else {
            breakSecondsRemaining = Int(breakDurationSeconds)
        }

        windowController.show(timer: self)

        breakTask?.cancel()
        breakTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if breakSecondsRemaining > 1 {
                    withAnimation { breakSecondsRemaining -= 1 }
                } else {
                    completeBreak()
                    return
                }
            }
        }
    }

    /// The actual break duration for the current break (used for progress calculations)
    var currentBreakTotal: Double {
        if pomodoroMode && pomodoroSessionCount % 4 == 0 {
            return 15 * 60
        }
        return breakDurationSeconds
    }

    private func completeBreak() {
        breakTask?.cancel()
        isOnBreak = false
        breaksCompletedToday += 1
        persistTodayBreaks()
        loadWeeklyStats()
        windowController.dismiss()
        startInterval()
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

    // MARK: - Weekly Stats Persistence

    private func loadTodayBreaks() {
        breaksCompletedToday = UserDefaults.standard.integer(forKey: "breaksToday")
        let lastDateStr = UserDefaults.standard.string(forKey: "breaksDate") ?? ""
        let todayStr = Self.todayString()
        if lastDateStr != todayStr {
            breaksCompletedToday = 0
            UserDefaults.standard.set(0, forKey: "breaksToday")
            UserDefaults.standard.set(todayStr, forKey: "breaksDate")
        }
    }

    private func persistTodayBreaks() {
        let todayStr = Self.todayString()
        UserDefaults.standard.set(breaksCompletedToday, forKey: "breaksToday")
        UserDefaults.standard.set(todayStr, forKey: "breaksDate")

        // Also store in weekly dict
        var weekly = UserDefaults.standard.dictionary(forKey: "weeklyBreaks") as? [String: Int] ?? [:]
        weekly[todayStr] = breaksCompletedToday
        // Prune entries older than 7 days
        let validDates = Set((0..<7).map { Self.dateString(daysAgo: $0) })
        weekly = weekly.filter { validDates.contains($0.key) }
        UserDefaults.standard.set(weekly, forKey: "weeklyBreaks")
    }

    func loadWeeklyStats() {
        let weekly = UserDefaults.standard.dictionary(forKey: "weeklyBreaks") as? [String: Int] ?? [:]
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        weeklyBreaks = (0..<7).reversed().map { daysAgo in
            let dateStr = Self.dateString(daysAgo: daysAgo)
            let count = (daysAgo == 0) ? breaksCompletedToday : (weekly[dateStr] ?? 0)
            let date = dateFormatter.date(from: dateStr) ?? Date()
            let label = daysAgo == 0 ? "Today" : dayFormatter.string(from: date)
            return DayStat(id: dateStr, label: label, count: count)
        }
    }

    // MARK: - Blink Animation

    private func startBlinkAnimation() {
        blinkTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3...6)))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.15)) { isBlinking = true }
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeInOut(duration: 0.15)) { isBlinking = false }
            }
        }
    }

    // MARK: - Sleep / Wake Detection

    private func observeSleepWake() {
        sleepObserverTask = Task {
            let sleepStream = NotificationCenter.default.notifications(
                named: NSWorkspace.willSleepNotification,
                object: NSWorkspace.shared
            )
            let screenLockStream = NotificationCenter.default.notifications(
                named: NSWorkspace.screensDidSleepNotification,
                object: NSWorkspace.shared
            )
            let wakeStream = NotificationCenter.default.notifications(
                named: NSWorkspace.didWakeNotification,
                object: NSWorkspace.shared
            )
            let screenUnlockStream = NotificationCenter.default.notifications(
                named: NSWorkspace.screensDidWakeNotification,
                object: NSWorkspace.shared
            )

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await _ in sleepStream { self.handleSleep() }
                }
                group.addTask {
                    for await _ in screenLockStream { self.handleSleep() }
                }
                group.addTask {
                    for await _ in wakeStream { self.handleWake() }
                }
                group.addTask {
                    for await _ in screenUnlockStream { self.handleWake() }
                }
            }
        }
    }

    nonisolated private func handleSleep() {
        Task { @MainActor in
            if !self.isPaused {
                self.wasRunningBeforeSleep = true
                self.pause()
            }
        }
    }

    nonisolated private func handleWake() {
        Task { @MainActor in
            if self.wasRunningBeforeSleep {
                self.wasRunningBeforeSleep = false
                self.resume()
            }
        }
    }

    // MARK: - Screen Sharing Detection

    private func observeScreenSharing() {
        screenSharingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                let sharing = isSharingScreen()
                if sharing && !isPaused {
                    wasRunningBeforeSleep = true
                    pause()
                } else if !sharing && isPaused && wasRunningBeforeSleep {
                    wasRunningBeforeSleep = false
                    resume()
                }
            }
        }
    }

    private func isSharingScreen() -> Bool {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String {
                let sharingApps = ["zoom.us", "Zoom", "Microsoft Teams", "Slack", "FaceTime", "Screen Sharing"]
                if sharingApps.contains(where: { ownerName.contains($0) }),
                   let layer = window[kCGWindowLayer as String] as? Int, layer > 0 {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Global Hot Key: Cmd+Shift+E

    private func registerGlobalHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4559_4553), id: 1)
        let keyCode: UInt32 = UInt32(kVK_ANSI_E)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr {
            hotKeyRef = ref
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let timer = Unmanaged<EyeStrainTimer>.fromOpaque(userData).takeUnretainedValue()
            if timer.isOnBreak {
                Task { @MainActor in timer.skipBreak() }
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    // MARK: - Helpers

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {}
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private static func dateString(daysAgo: Int) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }
}
