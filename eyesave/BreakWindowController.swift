//
//  BreakWindowController.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import AppKit
import SwiftUI

// MARK: - Screen Glow (depletes over break duration)

struct ScreenGlowView: View {
    var timer: EyeStrainTimer
    @State private var animate = false
    @State private var glowProgress: Double = 1.0

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .border(.cyan.opacity((animate ? 0.6 : 0.25) * glowProgress), width: 60)
                .blur(radius: 50)

            Rectangle()
                .fill(.clear)
                .border(.blue.opacity((animate ? 0.5 : 0.2) * glowProgress), width: 30)
                .blur(radius: 25)

            Rectangle()
                .fill(.clear)
                .border(.cyan.opacity((animate ? 0.35 : 0.1) * glowProgress), width: 8)
                .blur(radius: 8)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animate = true
            }
            withAnimation(.linear(duration: timer.currentBreakTotal)) {
                glowProgress = 0
            }
        }
    }
}

// MARK: - Screen Dim Overlay

struct ScreenDimView: View {
    @State private var appeared = false

    var body: some View {
        Rectangle()
            .fill(.black.opacity(appeared ? 0.15 : 0))
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Helper to create a fullscreen passthrough panel

private func makeFullscreenPanel(for screen: NSScreen) -> NSPanel {
    let panel = NSPanel(
        contentRect: screen.frame,
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    panel.ignoresMouseEvents = true
    panel.setFrame(screen.frame, display: true)
    panel.alphaValue = 0
    return panel
}

// MARK: - Window Controller

class BreakWindowController {
    private var pillPanels: [NSPanel] = []
    private var glowPanels: [NSPanel] = []
    private var dimPanels: [NSPanel] = []

    func show(timer: EyeStrainTimer) {
        guard pillPanels.isEmpty else { return }

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 110

        // Create overlays on ALL screens
        for screen in NSScreen.screens {
            let screenFrame = screen.frame

            // Dim panel
            let dimView = ScreenDimView()
            let dimHosting = NSHostingView(rootView: dimView)
            dimHosting.frame = NSRect(origin: .zero, size: screenFrame.size)

            let dim = makeFullscreenPanel(for: screen)
            dim.contentView = dimHosting
            dim.orderFrontRegardless()
            fadeIn(dim, duration: 0.5)
            dimPanels.append(dim)

            // Glow panel
            let glowView = ScreenGlowView(timer: timer)
            let glowHosting = NSHostingView(rootView: glowView)
            glowHosting.frame = NSRect(origin: .zero, size: screenFrame.size)

            let glow = makeFullscreenPanel(for: screen)
            glow.contentView = glowHosting
            glow.orderFrontRegardless()
            fadeIn(glow, duration: 0.6)
            glowPanels.append(glow)

            // Pill popup (centered on each screen)
            let content = BreakOverlayView(timer: timer)
                .environment(\.colorScheme, .dark)
            let hostingView = NSHostingView(rootView: content)
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = .clear
            hostingView.appearance = NSAppearance(named: .darkAqua)
            hostingView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)

            let pill = NSPanel(
                contentRect: hostingView.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            pill.isOpaque = false
            pill.backgroundColor = .clear
            pill.hasShadow = false
            pill.level = .floating
            pill.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            pill.contentView = hostingView
            pill.isMovableByWindowBackground = false
            pill.appearance = NSAppearance(named: .darkAqua)

            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.maxY - screenFrame.height * 0.2 - panelHeight / 2
            pill.setFrame(
                NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
                display: true
            )

            pill.alphaValue = 0
            pill.orderFrontRegardless()
            fadeIn(pill, duration: 0.35)
            pillPanels.append(pill)
        }
    }

    func dismiss() {
        for dim in dimPanels {
            fadeOutAndClose(dim, duration: 0.5)
        }
        dimPanels.removeAll()

        for glow in glowPanels {
            fadeOutAndClose(glow, duration: 0.5)
        }
        glowPanels.removeAll()

        for pill in pillPanels {
            fadeOutAndClose(pill, duration: 0.35)
        }
        pillPanels.removeAll()
    }

    private func fadeIn(_ panel: NSPanel, duration: Double) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    private func fadeOutAndClose(_ panel: NSPanel, duration: Double) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.close()
        })
    }
}
