//
//  Cat.swift
//  CharmingPanel
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
        var animationInterval: AnimationInterval = .default
        var withAnimation: Bool = true
    }
    
    enum Action {
        case changeType(CatType)
        case changeAnimationInterval(AnimationInterval)
        case toggleWithAnimation
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .changeType(type):
                state.type = type
                return .none
                
            case let .changeAnimationInterval(interval):
                state.animationInterval = interval
                return .none
                
            case . toggleWithAnimation:
                state.withAnimation.toggle()
                return .none
            }
        }
    }
}

extension Cat {
    enum AnimationInterval {
        case `default`
        case quick
        case custom(value: Double)
        
        var value: Double {
            switch self {
            case .default: 0.3
            case .quick: 0.07
            case .custom(let value): value
            }
        }
    }
}
