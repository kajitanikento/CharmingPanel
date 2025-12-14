//
//  ActorPanelView.swift
//  InputSourceDisplayApp
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
                Button("\(store.withAnimation ? "Stop" : "Start") animation") {
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
                let duration = 0.15
                withAnimation(isHover ? .easeIn(duration: duration) : .easeOut(duration: duration)) {
                    hoverAnimationProgress = isHover ? 1 : 0
                }
                
                if !isHover,
                   isLongPress {
                    isLongPress = false
                }
            }
            .onLongPressGesture(
                minimumDuration: 1,
                perform: { /** no operations */ },
                onPressingChanged: { isPress in
                    if isPress {
                        isLongPress = true
                    }
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
    }
    
    private var content: some View {
        ZStack {
            inputSourceLabel
            cat
        }
        .shadow(color: .black.opacity(0.2),radius: 4, x: 2, y: 2)
        .opacity(opacity)
    }
    
    // MARK: Subviews
    
    private var cat: some View {
        CatFrameForwardView(
            type: isLongPress ? .pickUp : .onBall,
            size: .init(width: Self.size.width - 20, height: Self.size.height - 20),
            withAnimation: store.withAnimation
        )
    }
    
    @ViewBuilder
    private var inputSourceLabel: some View {
        if !isLongPress {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                _inputSourceLabel
                    .padding(.bottom, 14)
                    .padding(.trailing, 4)
            }
            .frame(height: Self.size.height)
        }
    }
    
    private var _inputSourceLabel: some View {
        VStack {
            Text(shortLabel)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
//            Text(inputSourceObserver.currentName)
//                .font(.system(size: 11, weight: .medium))
//                .foregroundStyle(textColor.opacity(0.6))
//                .lineLimit(1)
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

