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
        var movingPanelPosition: MovePanelInfo = .zero
        var lastMouseLocation: (CGPoint, Date)?
        
        var isHide: Bool = false
        var withMove: Bool = false
        
        var pomodoroTimer: PomodoroTimer.State = .init()
        var cat: Cat.State = .init()
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
        case updateMovingPanelPosition(MovePanelInfo)
        
        // View inputs
        case toggleHidden(to: Bool? = nil)
        case toggleWithAnimation
        case toggleWithMove
        
        // Dependency inputs
        case changeInputSource(InputSource)
        
        // Child reducer
        case pomodoroTimer(PomodoroTimer.Action)
        case cat(Cat.Action)
    }
    
    enum CancelID: String {
        case moveCatOnCompleteTimer
    }
    
    @Dependency(\.inputSource) var inputSource
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    
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
                return handleMouseLocationTimerTicked(state: &state)
                
            case let .updateLastMouseLocation(location, date):
                state.lastMouseLocation = (location, date)
                return .none
                
            case let .updateMovingPanelPosition(info):
                state.movingPanelPosition = info
                return .none
                
            case let .toggleHidden(isHide):
                if let isHide {
                    state.isHide = isHide
                } else {
                    state.isHide.toggle()
                }
                return .none
            
            case .toggleWithAnimation:
                return .send(.cat(.toggleWithAnimation))
                
            case .toggleWithMove:
                state.withMove.toggle()
                return .none
                
            case let .changeInputSource(source):
                state.currentInputSource = source
                return .none
                
            case let .pomodoroTimer(action):
                switch action {
                case .completeTimer:
                    return .run { send in
                        let limitDate = self.date.now.addingTimeInterval(30)
                        for await _ in await self.clock.timer(interval: .seconds(0.1)) {
                            if self.date.now >= limitDate {
                                await send(.pomodoroTimer(.stopTimer))
                                return
                            }
                            let mouseLocation = NSEvent.mouseLocation
                            let position = CGPoint(
                                x: mouseLocation.x + 40 + ActorPanelView.size.width / 2,
                                y: mouseLocation.y
                            )
                            await send(.updateMovingPanelPosition(.init(position: position, animationDuration: 0.5)))
                        }
                    }
                    .cancellable(id: CancelID.moveCatOnCompleteTimer)
                case .stopTimer:
                    return .cancel(id: CancelID.moveCatOnCompleteTimer)
                    
                default:
                    break
                }
                return .none
                
            case .cat:
                return .none
            }
        }
        
        Scope(state: \.pomodoroTimer, action: \.pomodoroTimer) {
            PomodoroTimer()
        }
        
        Scope(state: \.cat, action: \.cat) {
            Cat()
        }
    }
    
    private func handleMouseLocationTimerTicked(state: inout State) -> Effect<ActorPanel.Action> {
        guard state.withMove else {
            return .none
        }
        
        let currentMouseLocation = NSEvent.mouseLocation
        guard let beforeMouseLocation = state.lastMouseLocation else {
            return .send(.updateLastMouseLocation(currentMouseLocation, date.now))
        }
        if beforeMouseLocation.0 != currentMouseLocation {
            return .send(.updateLastMouseLocation(currentMouseLocation, date.now))
        }
        // マウスポインタが一定時間同じ場所で止まっていたら寄っていく
        if date.now.timeIntervalSince(beforeMouseLocation.1) > 30 {
            return .run { send in
                await send(.updateMovingPanelPosition(.init(position: currentMouseLocation)))
                await send(.updateLastMouseLocation(currentMouseLocation, date.now))
            }
        }
        return .none
    }
}

extension ActorPanel {
    struct MovePanelInfo {
        var position: CGPoint
        var animationDuration: Double = 2
        
        static let zero: Self = .init(position: .zero, animationDuration: .zero)
    }
}
