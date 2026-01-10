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
    // MARK: - Property
    private let store: StoreOf<ActorPanel>
    
    private let actorPanel = NSPanel()
    private var actorHostingView: NSHostingView<ActorPanelView>!

    private var menuPanel: NSPanel?
    private var menuHostingView: NSHostingView<ActorPanelMenuView>?

    private var observations: [ObserveToken] = []
    
    // MARK: - Initialize
    
    init(
        store: StoreOf<ActorPanel>
    ) {
        self.store = store
        
        setupActor()
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
    
    // MARK: - Observe
    
    private func observeStore() {
        observations.append(observe { [weak self] in
            guard let self else { return }
            if store.isPanelHidden {
                hideActor()
            } else {
                showActor()
            }
        })
        
        observations.append(observe { [weak self] in
            guard let self,
                  let movingPanelPosition = store.movingPanelPosition
            else { return }
            _ = store.movingPanelPosition
            moveActor(to: movingPanelPosition.position, duration: movingPanelPosition.animationDuration)
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
    
    // MARK: - Actor
    
    private func setupActor() {
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
    
    private func moveActor(
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
    
    private func showActor(forceActive: Bool = false) {
        if forceActive {
            actorPanel.makeKeyAndOrderFront(nil)
        } else {
            actorPanel.orderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: forceActive)
    }
    
    private func hideActor() {
        actorPanel.orderOut(nil)
        // Actorを非表示にする場合はメニューも一緒に非表示にする
        hideMenu()
    }
    
    
    // MARK: - Menu
    
    private func showMenu() {
        // 既にメニューパネルが存在する場合はアクティブ化
        if let menuPanel = menuPanel {
            menuPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        setupMenu()
        
        // WORKAROUND: SwiftUIのViewでのサイズを取得するために見えない透過度で表示しておく
        menuPanel?.alphaValue = 0.01
        menuPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        if let menuSize = menuPanel?.frame.size {
            let menuOrigin = calculateMenuPosition(
                actorFrame: actorPanel.frame,
                menuSize: menuSize
            )
            menuPanel?.setFrame(
                CGRect(origin: menuOrigin, size: menuSize),
                display: true
            )
            menuPanel?.alphaValue = 1
        }
    }
    
    private func setupMenu() {
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

        NSLayoutConstraint.activate([
            newMenuHostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            newMenuHostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            newMenuHostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            newMenuHostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        menuPanel = newMenuPanel
        menuHostingView = newMenuHostingView
    }

    private func calculateMenuPosition(
        actorFrame: CGRect,
        menuSize: CGSize
    ) -> CGPoint {
        // actorPanelがあるスクリーンを取得
        guard let screen = NSScreen.screens.first(where: { screen in
            screen.frame.intersects(actorFrame)
        }) else {
            // スクリーンが見つからない場合はデフォルト位置(右側)
            return CGPoint(
                x: actorFrame.origin.x + actorFrame.width + 8,
                y: actorFrame.origin.y
            )
        }

        let visibleFrame = screen.visibleFrame
        let spacing: CGFloat = 8

        // 右側に配置した場合の座標を計算
        var menuX = actorFrame.origin.x + actorFrame.width + spacing
        var menuY = actorFrame.origin.y + actorFrame.height - menuSize.height - 8

        // 右側に配置した場合にスクリーンからはみ出すかチェック
        let menuRightEdge = menuX + menuSize.width
        if menuRightEdge > visibleFrame.maxX {
            // はみ出す場合は左側に配置
            menuX = actorFrame.origin.x - menuSize.width - spacing
        }

        // 上端を合わせた位置で配置
        // 上側にはみ出すかチェック
        let menuTopEdge = menuY + menuSize.height
        if menuTopEdge > visibleFrame.maxY {
            // はみ出す場合は調整
            menuY = visibleFrame.maxY - menuSize.height
        }

        // 下側にはみ出すかチェック
        if menuY < visibleFrame.minY {
            menuY = visibleFrame.minY
        }

        return CGPoint(x: menuX, y: menuY)
    }

    private func hideMenu() {
        guard let panel = menuPanel else { return }

        // フェードアウトアニメーションを実行
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)

            // フェードアウト
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                // アニメーション完了後にパネルを非表示
                panel.orderOut(nil)
                self?.menuPanel = nil
                self?.menuHostingView = nil
            }
        })
    }
}
