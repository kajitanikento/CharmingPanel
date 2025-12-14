//
//  Cat.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/14.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Cat {
    
    @ObservableState
    struct State {
        var type: CatType = .onBall
        var withAnimation: Bool = true
    }
    
    enum Action {
        case changeType(CatType)
        case toggleWithAnimation
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .changeType(type):
                state.type = type
                return .none
                
            case . toggleWithAnimation:
                state.withAnimation.toggle()
                return .none
            }
        }
    }
}
