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

    @State var hoverAnimationProgress: Double = 0
    
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
            if isShowInputSourceLabel {
                inputSourceLabel
            }
            cat
            if isShowTimerLabel {
                pomodoroTimer
            }
        }
        .onRightClick {
            store.send(.onRightClickActor)
        }
        .onLongPressGesture(
            minimumDuration: 1,
            perform: { /** no operations */ },
            onPressingChanged: { isPress in
                store.send(.onLongPressActor(isPress))
            }
        )
        .onEndWindowDrag(disable: !canMovePanel) {
            store.send(.onEndWindowDrag)
        }
        .onHover { isHover in
            store.send(.onHoverActor(isHover))
        }
    }
    
    private var pomodoroTimer: some View {
        PomodoroTimerView(
            store: store.scope(state: \.pomodoroTimer, action: \.pomodoroTimer)
        )
        .offset(y: -20)
    }
    
    private var cat: some View {
        CatView(
            store: store.scope(state: \.cat, action: \.cat)
        )
        .frame(width: Self.size.width - 12, height: Self.size.height - 12)
        .shadow(color: .black.opacity(0.2),radius: 4, x: 2, y: 2)
    }
    
    private var inputSourceLabel: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            _inputSourceLabel
                .padding(.bottom, 12)
                .padding(.trailing, 4)
        }
        .frame(height: Self.size.height)
        .shadow(color: .black.opacity(0.2),radius: 4, x: 2, y: 2)
    }
    
    private var _inputSourceLabel: some View {
        VStack {
            Text(store.currentInputSource.shortLabel)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 44, height: 44)
        .background(store.currentInputSource.themeColor)
        .clipShape(Circle())
    }
    
    // MARK: Helpers
    
    private var canMovePanel: Bool {
        store.canMovePanel
    }
    
    private var isShowInputSourceLabel: Bool {
        store.cat.type.shouldShowInputSource
    }
    
    private var isShowTimerLabel: Bool {
        store.cat.type.shouldShowTimer
    }
}

extension ActorPanel.State {
    var canMovePanel: Bool {
        if isShowMenu {
            return isHoverActor
        }
        return true
    }
}

extension CatType {
    var shouldShowInputSource: Bool {
        self != .pickUp
    }
    
    var shouldShowTimer: Bool {
        switch self {
        case .pickUp, .think: false
        default: true
        }
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
