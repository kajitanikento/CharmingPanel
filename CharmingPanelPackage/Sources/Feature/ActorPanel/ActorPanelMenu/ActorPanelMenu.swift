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
        var startedTimerIntervalMinute: Int?
    }
    
    enum Action {
        case onStartTimer(intervalMinute: Int)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onStartTimer(let intervalMinute):
                state.startedTimerIntervalMinute = intervalMinute
                return .none
                
            }
        }
    }
}
