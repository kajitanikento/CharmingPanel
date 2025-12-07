//
//  InputSourceObserver.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import SwiftUI
import AppKit
import Carbon
import Combine

final class InputSourceObserver: ObservableObject {
    @Published var currentName: String = "Unknown"
    
    private var observer: (any NSObjectProtocol)?
    
    init() {
        updateCurrentName()
        startObserving()
    }
    
    deinit {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }
    
    private func updateCurrentName() {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
            currentName = "Unknown"
            return
        }
        
        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            let cfStr = unsafeBitCast(namePtr, to: CFString.self)
            currentName = cfStr as String
        } else {
            currentName = "Unknown"
        }
    }
    
    private func startObserving() {
        let notificationName = Notification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged")
        observer = DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrentName()
        }
    }
}

enum InputSource {
    case abc
    case hiragana

    static func of(_ name: String) -> Self {
        // TODO: 仮実装
        if name.lowercased().contains("us") || name.contains("英数") || name.lowercased().contains("abc") {
            return .abc
        }
        return .hiragana
    }
}
