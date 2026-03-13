//
//  BreakWindowController.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import AppKit
import SwiftUI

struct ScreenGlowView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Wide soft glow
            Rectangle()
                .fill(.clear)
                .border(.cyan.opacity(animate ? 0.6 : 0.25), width: 60)
                .blur(radius: 50)

            // Medium glow
            Rectangle()
                .fill(.clear)
                .border(.blue.opacity(animate ? 0.5 : 0.2), width: 30)
                .blur(radius: 25)

            // Tight crisp edge
            Rectangle()
                .fill(.clear)
                .border(.cyan.opacity(animate ? 0.35 : 0.1), width: 8)
                .blur(radius: 8)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

class BreakWindowController {
    private var panel: NSPanel?
    private var glowPanel: NSPanel?

    func show(timer: EyeStrainTimer) {
        guard panel == nil else { return }

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 110

        // Screen edge glow
        if let screen = NSScreen.main {
            let screenFrame = screen.frame

            let glowView = ScreenGlowView()
            let glowHosting = NSHostingView(rootView: glowView)
            glowHosting.frame = NSRect(origin: .zero, size: screenFrame.size)

            let glow = NSPanel(
                contentRect: screenFrame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            glow.isOpaque = false
            glow.backgroundColor = .clear
            glow.hasShadow = false
            glow.level = .floating
            glow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            glow.contentView = glowHosting
            glow.ignoresMouseEvents = true
            glow.setFrame(screenFrame, display: true)
            glow.alphaValue = 0
            glow.orderFrontRegardless()

            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.6
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                glow.animator().alphaValue = 1
            }

            self.glowPanel = glow
        }

        // Pill popup
        let content = BreakOverlayView(timer: timer)
            .environment(\.colorScheme, .dark)
        let hostingView = NSHostingView(rootView: content)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        hostingView.appearance = NSAppearance(named: .darkAqua)
        hostingView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)

        let panel = NSPanel(
            contentRect: hostingView.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hostingView
        panel.isMovableByWindowBackground = false
        panel.appearance = NSAppearance(named: .darkAqua)

        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.maxY - screenFrame.height * 0.2 - panelHeight / 2
            panel.setFrame(
                NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
                display: true
            )
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        self.panel = panel
    }

    func dismiss() {
        if let glow = glowPanel {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.5
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                glow.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                glow.close()
                self?.glowPanel = nil
            })
        }

        guard let panel else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.close()
            self?.panel = nil
        })
    }
}
