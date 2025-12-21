//
//  HotKeyObserver.swift
//  CharmingPanelPackage
//
//  Created by kajitani kento on 2025/12/19.
//

import Carbon.HIToolbox
import Cocoa
import ComposableArchitecture
import DependenciesMacros

// MARK: - define dependency interface

@DependencyClient
struct HotKeyObserver {
    var stream: @Sendable () async -> AsyncStream<HotKey> = { .init { _ in } }
    var stop: @Sendable () async -> Void
}

extension DependencyValues {
    var hotKeyObserver: HotKeyObserver {
        get { self[HotKeyObserver.self] }
        set { self[HotKeyObserver.self] = newValue }
    }
}

extension HotKeyObserver: DependencyKey, Sendable {
    
    static var liveValue: HotKeyObserver {
        let live = HotKeyObserverLive.shared
        return .init(
            stream: {
                await live.stream
            },
            stop: {
                await live.stop()
            }
        )
    }
    
    static let previewValue: HotKeyObserver = .init(stream: { .init { _ in } }, stop: {})
}

// MARK: - defie live

final actor HotKeyObserverLive: Sendable {
    static let shared = HotKeyObserverLive()
    
    private var hotKeyRefs: [HotKey: EventHotKeyRef] = [:]
    private var continuation: AsyncStream<HotKey>.Continuation?
    
    init() {
        Task {
            await registerHotKeys()
        }
    }
    
    var stream: AsyncStream<HotKey> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func stop() {
        continuation?.finish()
        continuation = nil
    }
    
    private func onHotKeyPressed(eventId: UInt32) {
        guard let hotKey = HotKey.of(eventId: eventId) else {
            return
        }
        continuation?.yield(hotKey)
    }
    
    private func registerHotKeys() {
        registerHotKey(
            keyCode: UInt32(kVK_ANSI_K),
            modifiers: UInt32(cmdKey),
            hotKey: .callCat
        )
        registerHotKey(
            keyCode: UInt32(kVK_ANSI_U),
            modifiers: UInt32(cmdKey),
            hotKey: .toggleHidden
        )
    }
    
    private func registerHotKey(
        keyCode: UInt32,
        modifiers: UInt32,
        hotKey: HotKey
    ) {
        
        let hotKeyID = EventHotKeyID(
            signature: OSType(UInt32(truncatingIfNeeded: hotKey.fourCC)),
            id: hotKey.eventId
        )
        var hotKeyRef = hotKeyRefs[hotKey]
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        hotKeyRefs[hotKey] = hotKeyRef
        
        guard status == noErr else {
            print("RegisterEventHotKey failed:", status)
            return
        }
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            {  _, eventRef, _ in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                Task {
                    await HotKeyObserverLive.shared.onHotKeyPressed(eventId: hkID.id)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }
}

enum HotKey: String, CaseIterable {
    // rawValueはfourCCの形式
    case callCat = "CALL"
    case toggleHidden = "TOHI"
    
    var eventId: UInt32 {
        switch self {
        case .callCat: 1
        case .toggleHidden: 2
        }
    }
    
    var fourCC: UInt32 {
        var result: UInt32 = 0
        for u in self.rawValue.utf8.prefix(4) { result = (result << 8) + UInt32(u) }
        return result
    }
    
    static func of(eventId: UInt32) -> Self? {
        for type in Self.allCases {
            if type.eventId == eventId {
                return type
            }
        }
        return nil
    }
}
