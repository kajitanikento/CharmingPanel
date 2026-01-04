//
//  TimerHistoryStorage.swift
//  CharmingPanel
//
//  Created by claude on 2026/01/04.
//

import Foundation
import ComposableArchitecture
import DependenciesMacros

// MARK: - define dependency interface

@DependencyClient
struct TimerHistoryStorage {
    var load: @Sendable () -> [Int] = { [] }
    var save: @Sendable ([Int]) -> Void
}

extension DependencyValues {
    var timerHistoryStorage: TimerHistoryStorage {
        get { self[TimerHistoryStorage.self] }
        set { self[TimerHistoryStorage.self] = newValue }
    }
}

extension TimerHistoryStorage: DependencyKey, Sendable {

    static var liveValue: TimerHistoryStorage {
        .init(
            load: {
                TimerHistoryStorageLive.load()
            },
            save: { history in
                TimerHistoryStorageLive.save(history)
            }
        )
    }

    static let previewValue: TimerHistoryStorage = .init(
        load: { [] },
        save: { _ in }
    )

    static let testValue: TimerHistoryStorage = .init(
        load: { [] },
        save: { _ in }
    )
}

// MARK: - define live

enum TimerHistoryStorageLive {
    private static let userDefaultsKey = "timerIntervalMinuteHistory"

    static func load() -> [Int] {
        UserDefaults.standard.array(forKey: userDefaultsKey) as? [Int] ?? []
    }

    static func save(_ history: [Int]) {
        UserDefaults.standard.set(history, forKey: userDefaultsKey)
    }
}
