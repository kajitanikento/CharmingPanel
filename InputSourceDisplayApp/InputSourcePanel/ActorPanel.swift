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
        var withAnimation: Bool = true
        var withMove: Bool = true
    }
    
    enum Action {
        // Lifecycle
        case onAppear
        // View inputs
        case toggleHidden(to: Bool? = nil)
        case toggleWithAnimation
        case toggleWithMove
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                print("🍎 (｀・ω・´) < onAppear!")
                return .none
                
            case let .toggleHidden(isHide):
                if let isHide {
                    state.isHide = isHide
                } else {
                    state.isHide.toggle()
                }
                return .none
            
            case .toggleWithAnimation:
                state.withAnimation.toggle()
                return .none
                
            case .toggleWithMove:
                state.withMove.toggle()
                return .none
            }
        }
    }
}
