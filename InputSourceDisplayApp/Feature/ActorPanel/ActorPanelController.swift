//
//  ActorPanelController.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import AppKit
import SwiftUI
import Combine
import ComposableArchitecture

@MainActor
final class ActorPanelController {
    private let store: StoreOf<ActorPanel>
    
    private let panel = NSPanel()
    private var hostingView: NSHostingView<ActorPanelView>!
    
    private var observations: [ObserveToken] = []
    
    init(
        store: StoreOf<ActorPanel>
    ) {
        self.store = store
        setup()
        bind()
    }
    
    private func setup() {
        panel.styleMask = .borderless
        panel.backingType = .buffered
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isOpaque = false

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        hostingView = NSHostingView(rootView: ActorPanelView(
            store: store
        ))
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = contentView

        contentView.addSubview(hostingView)

        // hostingViewのサイズに合わせてcontentViewとpanelのサイズを設定
        NSLayoutConstraint.activate([
            hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        ])
        
        let newFrame = NSRect(origin: panel.frame.origin, size: ActorPanelView.size)
        panel.setFrame(newFrame, display: true)
    }
    
    private func bind() {
        observeStore()
        observeMouseLocation()
    }
    
    private func observeStore() {
        observations.append(observe { [weak self] in
            guard let self else { return }
            if store.isHide {
                hide()
            } else {
                show()
            }
        })
    }
    
    private func observeMouseLocation() {
        observations.append(observe { [weak self] in
            guard let self,
                  store.movingPanelPosition != .zero
            else { return }
            movePanel(to: store.movingPanelPosition)
        })
    }
    
    
    
    private func movePanel(to location: CGPoint) {
        let newLocation = CGPoint(
            x: location.x - ActorPanelView.size.width - 40,
            y: location.y - ActorPanelView.size.height / 2
        )
        let newFrame = CGRect(origin: newLocation, size: ActorPanelView.size)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 2
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            
            self.panel.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func show() {
        panel.orderFront(nil)
        NSApp.activate(ignoringOtherApps: false)
    }
    
    private func hide() {
        panel.orderOut(nil)
    }
}
