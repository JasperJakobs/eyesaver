//
//  BreakWindowController.swift
//  eyesave
//
//  Created by Jasper Jakobs on 13/03/2026.
//

import AppKit
import SwiftUI

class BreakWindowController {
    private var panel: NSPanel?

    func show(timer: EyeStrainTimer) {
        guard panel == nil else { return }

        let content = BreakOverlayView(timer: timer)
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(x: 0, y: 0, width: 340, height: 340)

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

        // Position 20% from top of screen, centered horizontally
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let panelWidth: CGFloat = 340
            let panelHeight: CGFloat = 340
            let x = screenFrame.midX - panelWidth / 2
            // macOS y-axis is bottom-up, so 20% from top = 80% from bottom
            let y = screenFrame.maxY - screenFrame.height * 0.2 - panelHeight / 2
            panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        self.panel = panel
    }

    func dismiss() {
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
