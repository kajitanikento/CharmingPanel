//
//  ActorPanelController.swift
//  CharmingPanel
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
    
    private let actorPanel = NSPanel()
    private var actorHostingView: NSHostingView<ActorPanelView>!

    private var menuPanel: NSPanel?
    private var menuHostingView: NSHostingView<ActorPanelMenuView>?

    private var observations: [ObserveToken] = []
    
    init(
        store: StoreOf<ActorPanel>
    ) {
        self.store = store
        
        setup()
        observeStore()
        observeNotification()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }
    
    private func setup() {
        actorPanel.styleMask = .borderless
        actorPanel.backingType = .buffered
        actorPanel.isMovableByWindowBackground = false
        actorPanel.isReleasedWhenClosed = false
        actorPanel.hidesOnDeactivate = false
        actorPanel.backgroundColor = .clear
        actorPanel.hasShadow = false
        actorPanel.isOpaque = false
        
        actorPanel.level = .floating
        actorPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        actorHostingView = NSHostingView(rootView: ActorPanelView(
            store: store
        ))
        actorHostingView.translatesAutoresizingMaskIntoConstraints = false
        
        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        actorPanel.contentView = contentView
        
        contentView.addSubview(actorHostingView)
        
        // hostingViewのサイズに合わせてcontentViewとpanelのサイズを設定
        NSLayoutConstraint.activate([
            actorHostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            actorHostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            actorHostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actorHostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
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
        
        observations.append(observe { [weak self] in
            guard let self,
                  let movingPanelPosition = store.movingPanelPosition
            else { return }
            _ = store.movingPanelPosition
            movePanel(to: movingPanelPosition.position, duration: movingPanelPosition.animationDuration)
            store.send(.finishMovePanelPosition)
        })
        
        observations.append(observe { [weak self] in
            guard let self else { return }
            let isShowMenu = store.isShowMenu
            if isShowMenu {
                showMenu()
            } else {
                hideMenu()
            }
        })
    }
    
    private func observeNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func didResignActive(_ notification: Notification) {
        store.send(.didResignActive)
    }
    
    private func movePanel(
        to location: CGPoint,
        duration: Double
    ) {
        let newLocation = CGPoint(
            x: location.x - actorPanel.frame.size.width / 2,
            y: location.y - actorPanel.frame.size.height / 2
        )
        let newFrame = CGRect(origin: newLocation, size: actorPanel.frame.size)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            
            self.actorPanel.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func show(forceActive: Bool = false) {
        if forceActive {
            actorPanel.makeKeyAndOrderFront(nil)
        } else {
            actorPanel.orderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: forceActive)
    }
    
    private func hide() {
        actorPanel.orderOut(nil)
        store.send(.toggleMenuHidden(to: true))
    }
    
    
    // MARK: - Menu
    
    private func showMenu() {
        // 既にメニューパネルが存在する場合はアクティブ化
        if let menuPanel = menuPanel {
            menuPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // 新しいメニューパネルを作成
        let newMenuPanel = NSPanel()
        newMenuPanel.styleMask = .borderless
        newMenuPanel.backingType = .buffered
        newMenuPanel.isMovableByWindowBackground = false
        newMenuPanel.isReleasedWhenClosed = false
        newMenuPanel.hidesOnDeactivate = false
        newMenuPanel.backgroundColor = .clear
        newMenuPanel.hasShadow = true
        newMenuPanel.isOpaque = false
        newMenuPanel.level = .floating
        newMenuPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // ActorPanelMenuViewを作成
        let menuView = ActorPanelMenuView(
            store: store.scope(state: \.menu, action: \.menu)
        )
        let newMenuHostingView = NSHostingView(rootView: menuView)
        newMenuHostingView.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        newMenuPanel.contentView = contentView

        contentView.addSubview(newMenuHostingView)

        // ホスティングビューのサイズに合わせてcontentViewとpanelのサイズを設定
        NSLayoutConstraint.activate([
            newMenuHostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            newMenuHostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            newMenuHostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            newMenuHostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            newMenuHostingView.widthAnchor.constraint(equalToConstant: ActorPanelMenuView.size.width),
            newMenuHostingView.heightAnchor.constraint(equalToConstant: ActorPanelMenuView.size.height)
        ])

        // メニューパネルの位置を計算（メインパネルの下に配置）
        let mainPanelFrame = actorPanel.frame
        let menuOrigin = CGPoint(
            x: mainPanelFrame.origin.x + (mainPanelFrame.width - ActorPanelMenuView.size.width) / 2,
            y: mainPanelFrame.origin.y - ActorPanelMenuView.size.height - 8
        )
        newMenuPanel.setFrame(
            CGRect(origin: menuOrigin, size: ActorPanelMenuView.size),
            display: true
        )

        // プロパティに保存
        menuPanel = newMenuPanel
        menuHostingView = newMenuHostingView

        // パネルを表示
        newMenuPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideMenu() {
        menuPanel?.orderOut(nil)
        menuPanel = nil
        menuHostingView = nil
    }
}
