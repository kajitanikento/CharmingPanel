//
//  ActorPanel.swift
//  CharmingPanel
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
        var movingPanelPosition: MovePanelInfo?
        var lastMouseLocation: (CGPoint, Date)?

        var isHide: Bool = false
        var withMove: Bool = false

        var latestTimerMinutes: [Int] = []

        var pomodoroTimer: PomodoroTimer.State = .init()
        var cat: Cat.State = .init()

        var panelSize: CGSize {
            ActorPanelView.size
        }
    }
    
    enum Action {
        // Lifecycle
        case onAppear
        case onDisappear

        // Store inputs
        case startObserveInputSource
        case startObserveHotKey
        case startObserveMouseLocation
        case mouseLocationTimerTicked
        case updateLastMouseLocation(CGPoint, Date)
        case startMovePanelPosition(MovePanelInfo)
        case finishMovePanelPosition
        case onPressHotKey(HotKey)
        case onStopTimer

        // View inputs
        case toggleHidden(to: Bool? = nil)
        case toggleWithAnimation
        case toggleWithMove
        case setLatestTimerMinute(Int)

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
    @Dependency(\.hotKeyObserver) var hotKeyObserver
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.startObserveInputSource)
                    await send(.startObserveHotKey)
                    await send(.startObserveMouseLocation)
                }
                
            case .onDisappear:
                return .run { _ in
                    await inputSource.stop()
                }
                
            case .startObserveInputSource:
                return .run { send in
                    for await newSouce in await self.inputSource.stream() {
                        await send(.changeInputSource(newSouce))
                    }
                }
                
            case .startObserveHotKey:
                return .run { send in
                    for await hotKey in await self.hotKeyObserver.stream() {
                        await send(.onPressHotKey(hotKey))
                    }
                }
                
            case .startObserveMouseLocation:
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.mouseLocationTimerTicked)
                    }
                }
                
            case .mouseLocationTimerTicked:
                return handleMouseLocationTimerTicked(state: &state)
                
            case let .updateLastMouseLocation(location, date):
                state.lastMouseLocation = (location, date)
                return .none
                
            case let .onPressHotKey(hotKey):
                switch hotKey {
                case .callCat:
                    if state.isHide {
                        state.isHide = false
                    }
                    state.movingPanelPosition = .init(position: NSEvent.mouseLocation, animationDuration: 0.3)
                case .toggleHidden:
                    state.isHide.toggle()
                    
                }
                
                return .none
                
            case .onStopTimer:
                return .cancel(id: CancelID.moveCatOnCompleteTimer)
                
            case let .startMovePanelPosition(info):
                state.movingPanelPosition = info
                return .none
                
            case .finishMovePanelPosition:
                state.movingPanelPosition = nil
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

            case let .setLatestTimerMinute(minute):
                state.latestTimerMinutes.insert(minute, at: 0)
                if state.latestTimerMinutes.count > 2 {
                    state.latestTimerMinutes.removeLast()
                }
                return .none

            case let .changeInputSource(source):
                state.currentInputSource = source
                return .none
                
            case let .pomodoroTimer(action):
                switch action {
                case .startTimer:
                    return .send(.cat(.changeType(.hasTimer)))
                    
                case .completeTimer:
                    let panelSize = state.panelSize
                    return .run { send in
                        await send(.cat(.changeType(.completeTimer)))
                        await send(.cat(.changeAnimationInterval(0.07)))
                        
                        let limitDate = self.date.now.addingTimeInterval(30)
                        for await _ in self.clock.timer(interval: .seconds(0.1)) {
                            guard !Task.isCancelled else { return }
                            if self.date.now >= limitDate {
                                await send(.pomodoroTimer(.stopTimer))
                                return
                            }
                            let mouseLocation = NSEvent.mouseLocation
                            let position = CGPoint(
                                x: mouseLocation.x + 40 + panelSize.width / 2,
                                y: mouseLocation.y
                            )
                            await send(.startMovePanelPosition(.init(position: position, animationDuration: 0.3)))
                        }
                    }
                    .cancellable(id: CancelID.moveCatOnCompleteTimer)
                case .stopTimer:
                    return .run { send in
                        await send(.cat(.changeType(.onBall)))
                        await send(.cat(.changeAnimationInterval(0.15)))
                        await send(.onStopTimer)
                    }
                }
                
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
                await send(.startMovePanelPosition(.init(position: currentMouseLocation)))
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
