//
//  AppDelegate.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import AppKit
import ComposableArchitecture

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = Store(initialState: ActorPanel.State()) {
        ActorPanel()
        #if DEBUG
            ._printChanges()
        #endif
    }
    
    private var statusItem: NSStatusItem!
    private var panelController: ActorPanelController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        panelController = ActorPanelController(store: store)
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        let bar = NSStatusBar.system
        statusItem = bar.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "keyboard",
                accessibilityDescription: "Input Source Indicator"
            )
            button.action = #selector(togglePanel)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show / Hide Indicator", action: #selector(togglePanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func togglePanel() {
        store.send(.toggleHidden())
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
