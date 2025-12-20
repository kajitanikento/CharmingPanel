//
//  ActorPanelView.swift
//  CharmingPanel
//
//  Created by kajitani kento on 2025/12/06.
//

import SwiftUI
import ComposableArchitecture

struct ActorPanelView: View {
    static let size = CGSize(width: 120, height: 170)
    
    @Bindable var store: StoreOf<ActorPanel>
    
    @State var isLongPress = false
    @State var hoverAnimationProgress: Double = 0
    
    var body: some View {
        content
            .contextMenu {
                if store.pomodoroTimer.isTimerRunning {
                    Button("Stop timer") {
                        store.send(.pomodoroTimer(.stopTimer))
                    }
                } else {
                    Button("Start timer(25m)") {
                        store.send(.pomodoroTimer(.startTimer(endDate: .now.addingTimeInterval(25 * 60))))
                    }
                    Button("Start timer(5m)") {
                        store.send(.pomodoroTimer(.startTimer(endDate: .now.addingTimeInterval(5 * 60))))
                    }
                }
                
                Button("\(store.state.cat.withAnimation ? "Stop" : "Start") animation") {
                    store.send(.toggleWithAnimation)
                }
                Button("\(store.withMove ? "Stop" : "Start") move") {
                    store.send(.toggleWithMove)
                }
                Button("Hide") {
                    store.send(.toggleHidden(to: true))
                }
            }
            .onHover { isHover in
                if store.pomodoroTimer.isComplete {
                    return
                }
                
                let duration = 0.15
                withAnimation(isHover ? .easeIn(duration: duration) : .easeOut(duration: duration)) {
                    hoverAnimationProgress = isHover ? 1 : 0
                }
                
                if !isHover,
                   isLongPress {
                    isLongPress = false
                }
            }
            .onTapGesture {
                if store.pomodoroTimer.isComplete {
                    store.send(.pomodoroTimer(.stopTimer))
                }
            }
            .onLongPressGesture(
                minimumDuration: 1,
                perform: { /** no operations */ },
                onPressingChanged: { isPress in
                    guard isPress,
                          !store.pomodoroTimer.isComplete else {
                        return
                    }
                    
                    isLongPress = true
                }
            )
            .gesture(
                WindowDragGesture()
                    .onEnded { _ in
                        if isLongPress {
                            isLongPress = false
                        }
                    }
            )
            .onAppear {
                store.send(.onAppear)
            }
            .onDisappear {
                store.send(.onDisappear)
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
    
    private var content: some View {
        ZStack {
            inputSourceLabel
            cat
            pomodoroTimer
        }
    }
    
    // MARK: Subviews
    
    private var pomodoroTimer: some View {
        PomodoroTimerView(
            store: store.scope(state: \.pomodoroTimer, action: \.pomodoroTimer)
        )
        .offset(y: -22)
        .opacity(isLongPress ? 0 : 1)
    }
    
    private var cat: some View {
        CatFrameForwardView(
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
    
    // MARK: Helpers
    
    private var opacity: Double {
        if isLongPress {
            return 1
        }
        return max(0.1, 1 - hoverAnimationProgress)
    }
    
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
}

#Preview {
    ActorPanelView(
        store: .init(initialState: .init()) { ActorPanel() }
    )
}

