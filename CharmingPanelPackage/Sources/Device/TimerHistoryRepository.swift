//
//  TimerHistoryRepository.swift
//  CharmingPanel
//
//  Created by claude on 2026/01/04.
//

import Foundation
import ComposableArchitecture
import DependenciesMacros

// MARK: - define dependency interface

@DependencyClient
struct TimerHistoryRepository {
    var load: @Sendable () -> [Int] = { [] }
    var save: @Sendable ([Int]) -> Void
}

extension DependencyValues {
    var timerHistoryRepository: TimerHistoryRepository {
        get { self[TimerHistoryRepository.self] }
        set { self[TimerHistoryRepository.self] = newValue }
    }
}

extension TimerHistoryRepository: DependencyKey, Sendable {

    static var liveValue: TimerHistoryRepository {
        .init(
            load: {
                TimerHistoryRepositoryLive.load()
            },
            save: { history in
                TimerHistoryRepositoryLive.save(history)
            }
        )
    }

    static let previewValue: TimerHistoryRepository = .init(
        load: { [] },
        save: { _ in }
    )

    static let testValue: TimerHistoryRepository = .init(
        load: { [] },
        save: { _ in }
    )
}

// MARK: - define live

enum TimerHistoryRepositoryLive {
    private static let userDefaultsKey = "timerIntervalMinuteHistory"

    static func load() -> [Int] {
        UserDefaults.standard.array(forKey: userDefaultsKey) as? [Int] ?? []
    }

    static func save(_ history: [Int]) {
        UserDefaults.standard.set(history, forKey: userDefaultsKey)
    }
}
