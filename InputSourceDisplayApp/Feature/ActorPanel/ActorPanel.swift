//
//  ActorPanel.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/14.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct ActorPanel {
    
    @ObservableState
    struct State {
        var currentInputSource: InputSource = .abc
        var movingPanelPosition: CGPoint = .zero
        var lastMouseLocation: (CGPoint, Date)?
        
        var isHide: Bool = false
        var withAnimation: Bool = true
        var withMove: Bool = true
    }
    
    enum Action {
        // Lifecycle
        case onAppear
        case onDisappear
        
        // Store inputs
        case startObserveInputSource
        case startObserveMouseLocation
        case mouseLocationTimerTicked
        case updateLastMouseLocation(CGPoint, Date)
        case updateMovingPanelPosition(CGPoint)
        
        // View inputs
        case toggleHidden(to: Bool? = nil)
        case toggleWithAnimation
        case toggleWithMove
        
        // Dependency inputs
        case changeInputSource(InputSource)
    }
    
    @Dependency(\.inputSource) var inputSource
    @Dependency(\.continuousClock) var clock
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.startObserveInputSource)
                    await send(.startObserveMouseLocation)
                }
                
            case .onDisappear:
                inputSource.stop()
                return .none
                
            case .startObserveInputSource:
                return .run { send in
                    for await newSouce in await self.inputSource.stream {
                        await send(.changeInputSource(newSouce))
                    }
                }
                
            case .startObserveMouseLocation:
                return .run { send in
                    for await _ in await self.clock.timer(interval: .seconds(1)) {
                        await send(.mouseLocationTimerTicked)
                    }
                }
                
            case .mouseLocationTimerTicked:
                guard state.withMove else {
                    return .none
                }
                
                let currentMouseLocation = NSEvent.mouseLocation
                guard let beforeMouseLocation = state.lastMouseLocation else {
                    return .send(.updateLastMouseLocation(currentMouseLocation, .now))
                }
                if beforeMouseLocation.0 != currentMouseLocation {
                    return .send(.updateLastMouseLocation(currentMouseLocation, .now))
                }
                // マウスポインタが一定時間同じ場所で止まっていたら寄っていく
                if Date().timeIntervalSince(beforeMouseLocation.1) > 30 {
                    return .run { send in
                        await send(.updateMovingPanelPosition(currentMouseLocation))
                        await send(.updateLastMouseLocation(currentMouseLocation, .now))
                    }
                }
                return .none
                
            case let .updateLastMouseLocation(location, date):
                state.lastMouseLocation = (location, date)
                return .none
                
            case let .updateMovingPanelPosition(position):
                state.movingPanelPosition = position
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
                
            case let .changeInputSource(source):
                state.currentInputSource = source
                return .none
            }
        }
    }
}


