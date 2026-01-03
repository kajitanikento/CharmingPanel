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
        // View inputs
        case onClickStartTimer(time: PomodoroTimer.PomodoroTime)
        case onClickStopTimer
        case onClickHidePanel
        case onClickQuitApp
        
        // Store inputs
        case stopTimer
    }
    
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onClickStartTimer(let time):
                state.startedTimerTime = time
                updateTime(intervalMinute: time.intervalMinute, state: &state)
                return .none
                
            case .onClickStopTimer:
                stopTimer(state: &state)
                return .none
                
            case .onClickHidePanel:
                return .none
                
            case .onClickQuitApp:
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
}
