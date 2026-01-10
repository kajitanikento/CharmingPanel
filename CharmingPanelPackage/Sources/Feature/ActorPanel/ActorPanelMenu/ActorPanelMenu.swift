//
//  ActorPanelMenu.swift
//  CharmingPanelPackage
//
//  Created by kajitani kento on 2025/12/29.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct ActorPanelMenu {

    @ObservableState
    struct State {
        var startedTimerTime: PomodoroTimer.PomodoroTime?
        var timeIntervalMinuteHistory: [Int] = []
    }

    enum Action {
        // Lifecycle
        case onAppear

        // View inputs
        case onClickStartTimer(time: PomodoroTimer.PomodoroTime)
        case onClickStopTimer
        case onClickHidePanel
        case onClickQuitApp
        case onDeleteTimerHistory(intervalMinute: Int)

        // Store inputs
        case stopTimer
    }

    @Dependency(\.timerHistoryRepository) var timerHistoryRepository

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                loadHistory(state: &state)
                return .none

            case .onClickStartTimer(let time):
                state.startedTimerTime = time
                updateTime(intervalMinute: time.intervalMinute, state: &state)
                saveHistory(state: state)
                return .none
                
            case .onClickStopTimer:
                stopTimer(state: &state)
                return .none

            case .onClickHidePanel:
                return .none

            case .onClickQuitApp:
                return .none

            case .onDeleteTimerHistory(let intervalMinute):
                deleteTimerHistory(intervalMinute: intervalMinute, state: &state)
                saveHistory(state: state)
                return .none

            case .stopTimer:
                stopTimer(state: &state)
                return .none
            }
        }
    }
    
    private func updateTime(intervalMinute: Int, state: inout State) {
        if let index = state.timeIntervalMinuteHistory.firstIndex(of: intervalMinute) {
            state.timeIntervalMinuteHistory.remove(at: index)
            state.timeIntervalMinuteHistory.insert(intervalMinute, at: 0)
            return
        }
        
        state.timeIntervalMinuteHistory.insert(intervalMinute, at: 0)
        
        if state.timeIntervalMinuteHistory.count > 5 {
            state.timeIntervalMinuteHistory.removeLast()
        }
    }
    
    private func stopTimer(state: inout State) {
        state.startedTimerTime = nil
    }

    private func deleteTimerHistory(intervalMinute: Int, state: inout State) {
        state.timeIntervalMinuteHistory.removeAll { $0 == intervalMinute }
    }

    private func loadHistory(state: inout State) {
        state.timeIntervalMinuteHistory = timerHistoryRepository.load()
    }

    private func saveHistory(state: State) {
        timerHistoryRepository.save(state.timeIntervalMinuteHistory)
    }
}
