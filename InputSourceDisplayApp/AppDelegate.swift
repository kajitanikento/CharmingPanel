//
//  AppDelegate.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let inputSourceManager = InputSourceManager()
    private var panelController: InputSourcePanelController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        panelController = InputSourcePanelController(inputSourceManager: inputSourceManager)
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
        panelController.show()
    }
    
    @objc private func togglePanel() {
        panelController.toggle()
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
