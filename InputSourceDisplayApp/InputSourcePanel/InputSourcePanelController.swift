//
//  InputSourcePanelController.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import AppKit
import SwiftUI
import Combine
import ComposableArchitecture

@MainActor
final class InputSourcePanelController {
    private let store: StoreOf<ActorPanel>
    
    private let panel = NSPanel()
    private let inputSourceObserver: InputSourceObserver
    private let panelContentCoordinator = PanelContentCoordinator()
    
    private var hostingView: NSHostingView<PanelContentView>!
    
    private var lastMouseLocation: (CGPoint, Date)?
    private var shouldMovePanel: Bool = true
    
    private var observeMouseLocationTimer: Timer?
    
    private var observations: [ObserveToken] = []
    private var cancellables = Set<AnyCancellable>()
    
    init(
        store: StoreOf<ActorPanel>,
        inputSourceObserver: InputSourceObserver
    ) {
        self.store = store
        self.inputSourceObserver = inputSourceObserver
        setup()

        resizePanel()
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

        hostingView = NSHostingView(rootView: PanelContentView(
            coordinator: panelContentCoordinator,
            inputSourceObserver: inputSourceObserver
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
    }
    
    private func bind() {
        observeStore()
        observeInputSource()
        observePanelContent()
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
    
    private func observeInputSource() {
        inputSourceObserver.$currentName
            .dropFirst() // 初回の値はスキップ
            .sink { [weak self] _ in
                self?.resizePanel()
            }
            .store(in: &cancellables)
    }
    
    private func observePanelContent() {
        panelContentCoordinator
            .inputTrigger
            .sink { [weak self] input in
                self?.handlePanelInput(input)
            }
            .store(in: &cancellables)
    }
        
    private func observeMouseLocation() {
        observeMouseLocationTimer = .scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.handleMouseLocationTimer()
            }
        }
    }
    
    private func handleMouseLocationTimer() {
        guard shouldMovePanel else { return }
        
        let currentMouseLocation = NSEvent.mouseLocation
        
        guard let beforeMouseLocation = lastMouseLocation else {
            self.lastMouseLocation = (currentMouseLocation, .now)
            return
        }
        if beforeMouseLocation.0 != currentMouseLocation {
            self.lastMouseLocation = (currentMouseLocation, .now)
            return
        }
        // マウスポインタが一定時間同じ場所で止まっていたら寄っていく
        if Date().timeIntervalSince(beforeMouseLocation.1) > 30 {
            movePanel(to: currentMouseLocation)
            self.lastMouseLocation = (currentMouseLocation, .now)
        }
    }
    
    private func movePanel(to location: CGPoint) {
        let newLocation = CGPoint(
            x: location.x - PanelContentView.size.width - 40,
            y: location.y - PanelContentView.size.height / 2
        )
        let newFrame = CGRect(origin: newLocation, size: PanelContentView.size)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 2
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            
            self.panel.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func handlePanelInput(_ input: PanelContentCoordinator.Input) {
        switch input {
        case .hide:
            hide()
        case let .toggleMovable(isMoving):
            shouldMovePanel = isMoving
        }
    }

    private func resizePanel() {
        let newFrame = NSRect(origin: panel.frame.origin, size: PanelContentView.size)

        panel.setFrame(newFrame, display: true)
    }
    
    private func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
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
