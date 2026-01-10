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

        var isPanelHidden = false
        var isShowMenu = false
        var shouldQuitApp = false
        
        var isLongPress = false
        var isHoverActor = false
        
        var pomodoroTimer: PomodoroTimer.State = .init()
        var cat: Cat.State = .init()
        
        var menu: ActorPanelMenu.State = .init()
    }
    
    enum Action {
        // Lifecycle
        case onAppear
        case onDisappear
        case didResignActive

        // Store inputs
        case startObserveInputSource
        case startObserveHotKey
        case startMovePanelPosition(MovePanelInfo)
        case finishMovePanelPosition
        case togglePanelHidden(to: Bool? = nil)
        case toggleMenuHidden(to: Bool? = nil)
        case quitApp
        case handle(HotKey)
        case cancel(CancelID)

        // View inputs
        case onClickTogglePanelHidden(to: Bool? = nil)
        case onRightClickActor
        case onLongPressActor(Bool)
        case onHoverActor(Bool)
        case onEndWindowDrag

        // Dependency inputs
        case onChangeInputSource(InputSource)

        // Child reducer
        case pomodoroTimer(PomodoroTimer.Action)
        case cat(Cat.Action)
        case menu(ActorPanelMenu.Action)
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
                    await send(.menu(.onAppear))
                }
                
            case .onDisappear:
                return .run { _ in
                    await inputSource.stop()
                }
                
            case .didResignActive:
                toggleMenuHidden(to: true, state: &state)
                return .none
                
            case .startObserveInputSource:
                return .run { send in
                    for await newSouce in await self.inputSource.stream() {
                        await send(.onChangeInputSource(newSouce))
                    }
                }
                
            case .startObserveHotKey:
                return .run { send in
                    for await hotKey in await self.hotKeyObserver.stream() {
                        await send(.handle(hotKey))
                    }
                }
                
            case .togglePanelHidden(let isHide):
                togglePanelHidden(to: isHide, state: &state)
                return .none
                
            case .toggleMenuHidden(let isHide):
                toggleMenuHidden(to: isHide, state: &state)
                return .none
                
            case .quitApp:
                state.shouldQuitApp = true
                return .none
                
            case let .handle(hotKey):
                switch hotKey {
                case .callCat:
                    if state.isPanelHidden {
                        state.isPanelHidden = false
                    }
                    state.movingPanelPosition = .init(position: NSEvent.mouseLocation, animationDuration: 0.3)
                case .toggleHidden:
                    togglePanelHidden(state: &state)
                    
                }
                
                return .none
                
            case .cancel(let id):
                return .cancel(id: id)
                
            case let .startMovePanelPosition(info):
                state.movingPanelPosition = info
                return .none
                
            case .finishMovePanelPosition:
                state.movingPanelPosition = nil
                return .none
                
            case let .onClickTogglePanelHidden(isHide):
                togglePanelHidden(to: isHide, state: &state)
                return .none
                
            case .onRightClickActor:
                toggleMenuHidden(state: &state)
                return .none
                
            case .onLongPressActor(let isLongPress):
                if #available(macOS 26.0, *) {
                    updateLongPress(to: isLongPress, state: &state)
                }
                guard isLongPress else {
                    return .none
                }
                if #unavailable(macOS 26.0) {
                    updateLongPress(to: true, state: &state)
                }
                
                if state.pomodoroTimer.isComplete {
                    return .send(.pomodoroTimer(.stopTimer))
                }
                
                if state.isShowMenu {
                    toggleMenuHidden(to: true, state: &state)
                }
                return .none
                
            case .onHoverActor(let isHover):
                state.isHoverActor = isHover
                if !isHover,
                   state.isLongPress {
                    updateLongPress(to: false, state: &state)
                }
                
                return .none
                
            case .onEndWindowDrag:
                if state.isLongPress {
                    updateLongPress(to: false, state: &state)
                }
                return .none

            case let .onChangeInputSource(source):
                state.currentInputSource = source
                return .none
                
            case let .pomodoroTimer(action):
                switch action {
                case .startTimer:
                    updateCatType(state: &state)
                    return .none
                    
                case .completeTimer:
                    return .run { send in
                        await send(.toggleMenuHidden(to: true))
                        await send(.cat(.changeAnimationInterval(.quick)))
                        
                        let limitDate = self.date.now.addingTimeInterval(30)
                        for await _ in self.clock.timer(interval: .seconds(0.1)) {
                            guard !Task.isCancelled else { return }
                            if self.date.now >= limitDate {
                                await send(.pomodoroTimer(.stopTimer))
                                return
                            }
                            await send(.startMovePanelPosition(.init(position: NSEvent.mouseLocation, animationDuration: 0.3)))
                        }
                    }
                    .cancellable(id: CancelID.moveCatOnCompleteTimer)
                case .stopTimer:
                    updateCatType(state: &state)
                    return .run { send in
                        await send(.cat(.changeAnimationInterval(.default)))
                        await send(.cancel(.moveCatOnCompleteTimer))
                        await send(.menu(.stopTimer))
                    }
                }
                
            case .cat:
                return .none
                
            case .menu(let action):
                return .run { send in
                    switch action {
                    case .onClickStartTimer(let time):
                        await send(.pomodoroTimer(.startTimer(time: time)))
                        
                    case .onClickStopTimer:
                        await send(.pomodoroTimer(.stopTimer))
                        
                    case .onClickHidePanel:
                        await send(.togglePanelHidden(to: true))
                        
                    case .onClickQuitApp:
                        await send(.quitApp)
                        
                    default:
                        break
                    }
                    
                    if action.shouldHideMenu {
                        // menuのアクションが実行されたらメニューを非表示にする
                        await send(.toggleMenuHidden(to: true))
                    }
                }
            }
        }
        
        Scope(state: \.pomodoroTimer, action: \.pomodoroTimer) {
            PomodoroTimer()
        }
        
        Scope(state: \.cat, action: \.cat) {
            Cat()
        }
        
        Scope(state: \.menu, action: \.menu) {
            ActorPanelMenu()
        }
    }
    
    // MARK: Helpers
    
    private func togglePanelHidden(to isHidden: Bool? = nil, state: inout State) {
        if let isHidden {
            state.isPanelHidden = isHidden
        } else {
            state.isPanelHidden.toggle()
        }
        
        // パネルが非表示になった場合はメニューも非表示にする
        if state.isPanelHidden {
            toggleMenuHidden(to: true, state: &state)
        }
    }
    
    private func toggleMenuHidden(to isHidden: Bool? = nil, state: inout State) {
        if let isHidden {
            state.isShowMenu = !isHidden
        } else {
            state.isShowMenu.toggle()
        }
        updateCatType(state: &state)
    }
    
    private func updateLongPress(to isLongPress: Bool, state: inout State) {
        state.isLongPress = isLongPress
        
        updateCatType(state: &state)
    }
    
    private func updateCatType(state: inout State) {
        if state.isLongPress {
            state.cat.type = .pickUp
            return
        }
        if state.isShowMenu {
            state.cat.type = .think
            return
        }
        if state.pomodoroTimer.isComplete {
            state.cat.type = .completeTimer
            return
        }
        if state.pomodoroTimer.isTimerRunning {
            state.cat.type = .hasTimer
            return
        }
        state.cat.type = .onBall
    }
}

extension ActorPanel {
    struct MovePanelInfo {
        var position: CGPoint
        var animationDuration: Double = 2
        
        static let zero: Self = .init(position: .zero, animationDuration: .zero)
    }
}

extension ActorPanelMenu.Action {
    var shouldHideMenu: Bool {
        switch self {
        case .onClickHidePanel,
                .onClickQuitApp:
            true
        default:
            false
        }
    }
}
