//
//  HotKeyObserver.swift
//  InputSourceDisplayPackage
//
//  Created by kajitani kento on 2025/12/19.
//

import Carbon.HIToolbox
import Cocoa
import ComposableArchitecture

final actor HotKeyObserver: Sendable {
    static let shared = HotKeyObserver()
    
    private var hotKeyRef: EventHotKeyRef?
    private var continuation: AsyncStream<Void>.Continuation?
    
    init() {
        Task {
            await registerHotKey()
        }
    }
    
    var stream: AsyncStream<Void> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func stop() {
        continuation?.finish()
        continuation = nil
    }
    
    private func onHotKeyPressed() {
        continuation?.yield(())
    }
    
    private func registerHotKey() {
        // ⌘K
        let keyCode: UInt32 = UInt32(kVK_ANSI_K)
        let modifiers: UInt32 = UInt32(cmdKey)
        
        var hotKeyID = EventHotKeyID(
            signature: OSType(UInt32(truncatingIfNeeded: HotKeyID.callCat.fourCC)),
            id: 1
        )
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
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
                
                if hkID.id == 1 {
                    HotKeyObserver.shared.onHotKeyPressed()
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

enum HotKeyID: String {
    case callCat
    
    var fourCC: UInt32 {
        var result: UInt32 = 0
        for u in self.rawValue.utf8.prefix(4) { result = (result << 8) + UInt32(u) }
        return result
    }
}

// MARK: define swift dependency

extension DependencyValues {
    var hotKeyObserver: HotKeyObserver {
        get { self[HotKeyObserverKey.self] }
        set { self[HotKeyObserverKey.self] = newValue }
    }
}

private enum HotKeyObserverKey: DependencyKey, Sendable {
    
    static let liveValue: HotKeyObserver = .shared
    
}
