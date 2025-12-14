//
//  ActorPanel.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/14.
//

import ComposableArchitecture

@Reducer
struct ActorPanel {
    
    @ObservableState
    struct State {
        var isHide: Bool = false
    }
    
    enum Action {
        case toggleHidden(to: Bool? = nil)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .toggleHidden(isHide):
                if let isHide {
                    state.isHide = isHide
                } else {
                    state.isHide.toggle()
                }
                return .none
            }
        }
    }
}
