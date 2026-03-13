//
//  eyesaveApp.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import SwiftUI

@main
struct eyesaveApp: App {
    @State private var timer = EyeStrainTimer()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timer: timer)
        } label: {
            Image(systemName: timer.isPaused ? "eye.slash" : "eye")
        }
        .menuBarExtraStyle(.window)
    }
}
