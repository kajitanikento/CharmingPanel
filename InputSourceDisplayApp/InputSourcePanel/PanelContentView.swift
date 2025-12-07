//
//  PanelContentView.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import SwiftUI

struct PanelContentView: View {
    static let size = CGSize(width: 120, height: 170)
    
    @ObservedObject var coordinator: PanelContentCoordinator
    @ObservedObject var inputSourceObserver: InputSourceObserver
    
    @State var isStopAnimation = false
    
    @State var isLongPress = false
    @State var hoverAnimationProgress: Double = 0
    
    var currentInputSource: InputSource {
        .of(inputSourceObserver.currentName)
    }
    
    var body: some View {
        content
            .contextMenu {
                Button("\(isStopAnimation ? "Start" : "Stop") animation") {
                    isStopAnimation.toggle()
                }
                Button("Hide") {
                    coordinator.onSelectHide()
                }
            }
            .onHover { isHover in
                let duration = 0.15
                withAnimation(isHover ? .easeIn(duration: duration) : .easeOut(duration: duration)) {
                    hoverAnimationProgress = isHover ? 1 : 0
                }
            }
            .onLongPressGesture(
                minimumDuration: 0,
                perform: { /** no operations */ },
                onPressingChanged: { isPress in
                    isLongPress = isPress
                }
            )
    }
    
    private var content: some View {
        ZStack {
            inputSourceLabel
            cat
        }
        .shadow(radius: 6)
        .opacity(opacity)
    }
    
    // MARK: Subviews
    
    private var cat: some View {
        CatFrameForwardView(
            type: isLongPress ? .pickUp : .onBall,
            size: .init(width: Self.size.width - 20, height: Self.size.height - 20),
            isStopAnimation: $isStopAnimation
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
        switch currentInputSource {
        case .abc: "A"
        case .hiragana: "あ"
        }
    }
    
    private var textColor: Color {
        switch currentInputSource {
        case .abc: .white
        case .hiragana: .white
        }
    }
    
    private var backgroundColor: Color {
        switch currentInputSource {
        case .abc: .blue
        case .hiragana: .red
        }
    }
}

#Preview {
    PanelContentView(
        coordinator: .init(),
        inputSourceObserver: .init()
    )
}

