//
//  InputSourcePanelController.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import AppKit
import SwiftUI
import Combine

final class InputSourcePanelController {
    private let panel: NSPanel
    private let manager: InputSourceObserver
    private let panelContentCoordinator = PanelContentCoordinator()
    private let hostingView: NSHostingView<PanelContentView>
    private var cancellables = Set<AnyCancellable>()
    
    init(inputSourceObserver: InputSourceObserver) {
        self.manager = inputSourceObserver

        let rect = NSRect(x: 200, y: 200, width: 0, height: 0)
        panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

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
            inputSourceObserver: manager
        ))
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = contentView

        contentView.addSubview(hostingView)

        // hostingViewのサイズに合わせてcontentViewとpanelのサイズを設定
        NSLayoutConstraint.activate([
            // hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            // hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        resizePanel()
        bind()
    }
    
    private func bind() {
        // currentNameの変更を監視してパネルをリサイズ
        manager.$currentName
            .dropFirst() // 初回の値はスキップ
            .sink { [weak self] _ in
                self?.resizePanel()
            }
            .store(in: &cancellables)
        
        panelContentCoordinator
            .inputTrigger
            .sink { [weak self] input in
                self?.handlePanelInput(input)
            }
            .store(in: &cancellables)
    }
    
    private func handlePanelInput(_ input: PanelContentCoordinator.Input) {
        switch input {
        case .hide:
            hide()
        }
    }

    private func resizePanel() {
        let newFrame = NSRect(origin: panel.frame.origin, size: PanelContentView.size)
        panel.contentView?.layer?.cornerRadius = PanelContentView.size.width / 2

        panel.setFrame(newFrame, display: true)
    }
    
    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        panel.orderFront(nil)
        NSApp.activate(ignoringOtherApps: false)
    }
    
    func hide() {
        panel.orderOut(nil)
    }
}
