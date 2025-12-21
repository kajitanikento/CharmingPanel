//
//  InputSourceObserver.swift
//  CharmingPanel
//
//  Created by kajitani kento on 2025/12/06.
//

import SwiftUI
import AppKit
import Carbon
import ComposableArchitecture
import DependenciesMacros

// MARK: - define dependency interface

@DependencyClient
struct InputSourceObserver {
    var stream: @Sendable () async -> AsyncStream<InputSource> = { .init { _ in } }
    var stop: @Sendable () async -> Void
}

extension DependencyValues {
    var inputSource: InputSourceObserver {
        get { self[InputSourceObserver.self] }
        set { self[InputSourceObserver.self] = newValue }
    }
}

extension InputSourceObserver: DependencyKey, Sendable {
    
    static var liveValue: InputSourceObserver {
        let live = InputSourceObserverLive()
        return .init(
            stream: {
                await live.stream
            },
            stop: {
                await live.stop()
            }
        )
    }
    
    static let previewValue: InputSourceObserver = .init(stream: { .init { _ in } }, stop: {})
}

// MARK: - define live

actor InputSourceObserverLive {
    private var observer: (any NSObjectProtocol)?
    private var continuation: AsyncStream<InputSource>.Continuation?

    init() {}
    
    var stream: AsyncStream<InputSource> {
        startObserving()
        return AsyncStream { continuation in
            self.continuation = continuation
            
            Task {
                await updateCurrent()
            }
        }
    }
    
    func stop() {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        continuation?.finish()
        continuation = nil
    }
    
    private func getCurrent() async -> InputSource {
        InputSource.of(await getCurrentInputSourceName())
    }

    @MainActor
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

    private func updateCurrent() async {
        continuation?.yield(await getCurrent())
    }

    private func startObserving() {
        let notificationName = Notification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged")
        observer = DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.updateCurrent()
            }
        }
    }
}

enum InputSource: Sendable {
    case abc
    case hiragana

    nonisolated static func of(_ name: String) -> Self {
        // TODO: サポート外の言語の考慮を追加する
        if name.lowercased().contains("us") || name.contains("英数") || name.lowercased().contains("abc") {
            return .abc
        }
        return .hiragana
    }
}
