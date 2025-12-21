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
    
    var body: some View {
        content
            .contextMenu {
                if store.pomodoroTimer.isTimerRunning {
                    Button("Stop timer", systemImage: "stop.fill") {
                        store.send(.pomodoroTimer(.stopTimer))
                    }
                } else {
                    Menu("Start timer", systemImage: "gauge.with.needle") {
                        if !store.latestTimerMinutes.isEmpty {
                            Text("recent")
                            ForEach(store.latestTimerMinutes.indices, id: \.self) { index in
                                let minute = store.latestTimerMinutes[index]
                                Button("\(minute)m") {
                                    store.send(.pomodoroTimer(.startTimer(endDate: .now.addingTimeInterval(Double(minute * 60)))))
                                    store.send(.setLatestTimerMinute(minute))
                                }
                            }

                            Divider()
                        }

                        Menu("choose") {
                            ForEach(1...12, id: \.self) { num in
                                let minute = num * 5
                                Button("\(minute)m") {
                                    store.send(.pomodoroTimer(.startTimer(endDate: .now.addingTimeInterval(Double(minute * 60)))))
                                    store.send(.setLatestTimerMinute(minute))
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("\(store.state.cat.withAnimation ? "Stop" : "Start") animation", systemImage: "figure.run") {
                    store.send(.toggleWithAnimation)
                }
                
                Divider()
                
                Button("Hide panel", systemImage: "eye.slash") {
                    store.send(.toggleHidden(to: true))
                }
            }
            .onHover { isHover in
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
        store: .init(
            initialState: {
                var state = ActorPanel.State()
                state.pomodoroTimer.time = .init(startDate: .now, endDate: .now.addingTimeInterval(600))
                state.cat.type = .hasTimer
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

