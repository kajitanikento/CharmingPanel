//
//  InputSourceObserver.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import SwiftUI
import AppKit
import Carbon
import ComposableArchitecture

final class InputSourceObserver {
    private var observer: (any NSObjectProtocol)?
    private var continuation: AsyncStream<InputSource>.Continuation?

    init() {}
    
    var stream: AsyncStream<InputSource> {
        startObserving()
        return AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(getCurrent())
        }
    }
    
    func stop() {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        continuation?.finish()
        continuation = nil
    }
    
    private func getCurrent() -> InputSource {
        InputSource.of(getCurrentInputSourceName())
    }

    private func getCurrentInputSourceName() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
            return "Unknown"
        }

        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            let cfStr = unsafeBitCast(namePtr, to: CFString.self)
            return cfStr as String
        }
        
        return "Unknown"
    }

    private func updateCurrent() {
        continuation?.yield(getCurrent())
    }

    private func startObserving() {
        let notificationName = Notification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged")
        observer = DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrent()
        }
    }
}

enum InputSource {
    case abc
    case hiragana

    static func of(_ name: String) -> Self {
        // TODO: サポート外の言語の考慮を追加する
        if name.lowercased().contains("us") || name.contains("英数") || name.lowercased().contains("abc") {
            return .abc
        }
        return .hiragana
    }
}

// MARK: define swift dependency

extension DependencyValues {
    var inputSource: InputSourceObserver {
        get { self[InputSourceKey.self] }
        set { self[InputSourceKey.self] = newValue }
    }
}

private enum InputSourceKey: DependencyKey {
    
    static let liveValue: InputSourceObserver = .init()
    
}
