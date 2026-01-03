//
//  AppDelegate.swift
//  CharmingPanel
//
//  Created by kajitani kento on 2025/12/06.
//

import AppKit
import ComposableArchitecture

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = Store(initialState: ActorPanel.State()) {
        ActorPanel()
        #if DEBUG
            ._printChanges()
        #endif
    }

    private var statusItem: NSStatusItem!
    private var toggleHiddenMenuItem: NSMenuItem!
    private var showPanelImage: NSImage? { NSImage(systemSymbolName: "eye", accessibilityDescription: "Switch panel visibility") }
    private var hidePanelImage: NSImage? { NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Switch panel visibility") }
    
    private var panelController: ActorPanelController!
    
    private var observations: [ObserveToken] = []

    public override init() {
        super.init()
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        panelController = ActorPanelController(store: store)
        setupStatusItem()
        observe()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let image = NSImage(resource: .init(name: "MenuIcon", bundle: .module))
            image.size = .init(width: 20, height: 20)
            button.image = image
            button.action = #selector(togglePanel)
            button.target = self
        }
        
        let menu = NSMenu()
        toggleHiddenMenuItem = NSMenuItem(title: "", action: #selector(togglePanel), keyEquivalent: "u")
        toggleHiddenMenuItem.image = hidePanelImage
        updateToggleHiddenMenuItemTitle()
        menu.addItem(toggleHiddenMenuItem)
        menu.addItem(NSMenuItem.separator())
        let quitMenuItem = NSMenuItem(title: "アプリを終了", action: #selector(quit), keyEquivalent: "q")
        quitMenuItem.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Quit application")
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
    }
    
    private func observe() {
        observations.append(observe { [unowned self] in
            _ = store.isPanelHidden
            updateToggleHiddenMenuItemTitle()
        })
        
        observations.append(observe { [unowned self] in
            _ = store.shouldQuitApp
            if store.shouldQuitApp {
                quit()
            }
        })
    }
    
    private func updateToggleHiddenMenuItemTitle() {
        toggleHiddenMenuItem.title = "パネルを\(store.isPanelHidden ? "表示" : "非表示")"
        toggleHiddenMenuItem.image = store.isPanelHidden ? showPanelImage : hidePanelImage
    }
    
    @objc private func togglePanel() {
        store.send(.onClickTogglePanelHidden())
        updateToggleHiddenMenuItemTitle()
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
