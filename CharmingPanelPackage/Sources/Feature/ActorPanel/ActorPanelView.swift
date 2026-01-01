//
//  ActorPanelView.swift
//  CharmingPanel
//
//  Created by kajitani kento on 2025/12/06.
//

import SwiftUI
import ComposableArchitecture

struct ActorPanelView: View {
    nonisolated static let size = CGSize(width: 120, height: 170)
    
    @Bindable var store: StoreOf<ActorPanel>

    @State var isLongPress = false
    @State var hoverAnimationProgress: Double = 0
    @State var isHoverActor = false
    
    var body: some View {
        content
            .onAppear {
                store.send(.onAppear)
            }
            .onDisappear {
                store.send(.onDisappear)
            }
    }
    
    private var content: some View {
        actorContent
    }
    
    // MARK: Subviews
    
    private var actorContent: some View {
        ZStack {
            inputSourceLabel
            cat
            pomodoroTimer
        }
        .onRightClick {
            store.send(.toggleMenuHidden())
        }
        .onLongPressGesture(
            minimumDuration: 1,
            perform: { /** no operations */ },
            onPressingChanged: { isPress in
                guard isPress else {
                    return
                }
                if store.pomodoroTimer.isComplete {
                    store.send(.pomodoroTimer(.stopTimer))
                    return
                }
                if store.isShowMenu {
                    store.send(.toggleMenuHidden(to: true))
                }
                isLongPress = true
            }
        )
        .onEndWindowDrag(disable: !canMovePanel) {
            if isLongPress {
                isLongPress = false
            }
        }
        .onHover { isHover in
            isHoverActor = isHover
            if !isHover,
               isLongPress {
                isLongPress = false
            }
        }
        .onChange(of: isLongPress) {
            if isLongPress {
                store.send(.cat(.changeType(.pickUp)))
                return
            }
            if store.pomodoroTimer.isTimerRunning {
                store.send(.cat(.changeType(.hasTimer)))
                return
            }
            store.send(.cat(.changeType(.onBall)))
        }
    }
    
    private var pomodoroTimer: some View {
        PomodoroTimerView(
            store: store.scope(state: \.pomodoroTimer, action: \.pomodoroTimer)
        )
        .offset(y: -20)
        .opacity(isLongPress ? 0 : 1)
    }
    
    private var cat: some View {
        CatView(
            store: store.scope(state: \.cat, action: \.cat)
        )
        .frame(width: Self.size.width - 12, height: Self.size.height - 12)
        .shadow(color: .black.opacity(0.2),radius: 4, x: 2, y: 2)
    }
    
    @ViewBuilder
    private var inputSourceLabel: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            _inputSourceLabel
                .padding(.bottom, 12)
                .padding(.trailing, 4)
        }
        .frame(height: Self.size.height)
        .shadow(color: .black.opacity(0.2),radius: 4, x: 2, y: 2)
        .opacity(isLongPress ? 0 : 1)
    }
    
    private var _inputSourceLabel: some View {
        VStack {
            Text(shortLabel)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
        }
        .frame(width: 44, height: 44)
        .background(backgroundColor)
        .clipShape(Circle())
    }
    
    private var menuConetnt: some View {
        ActorPanelMenuView(
            store: store.scope(state: \.menu, action: \.menu)
        )
        .frame(width: ActorPanelMenuView.size.width - 4, height: ActorPanelMenuView.size.height - 4)
        .offset(x: -6, y: 4)
        .shadow(color: .black.opacity(0.2),radius: 4, x: 2, y: 2)
    }
    
    // MARK: Helpers

    private var shortLabel: String {
        switch store.currentInputSource {
        case .abc: "A"
        case .hiragana: "あ"
        }
    }
    
    private var textColor: Color {
        switch store.currentInputSource {
        case .abc: .white
        case .hiragana: .white
        }
    }
    
    private var backgroundColor: Color {
        switch store.currentInputSource {
        case .abc: .blue
        case .hiragana: .red
        }
    }
    
    var canMovePanel: Bool {
        if store.isShowMenu {
            return isHoverActor
        }
        return true
    }
}

#Preview {
    ActorPanelView(
        store: .init(
            initialState: {
                var state = ActorPanel.State()
                state.cat.type = .onBall
                state.isShowMenu = true
                return state
            }()
        ) {
            withDependencies {
                $0.inputSource.stream = { .init { continuation in
                    continuation.yield(.hiragana)
                } }
            } operation: {
                ActorPanel()
            }
        }
    )
}
