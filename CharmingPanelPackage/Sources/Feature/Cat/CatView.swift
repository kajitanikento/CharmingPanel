//
//  CatView.swift
//  CharmingPanel
//
//  Created by kajitani kento on 2025/12/07.
//

import ComposableArchitecture
import SwiftUI

enum CatType {
    case onBall
    case hasTimer
    case completeTimer
    case pickUp
}

struct CatView: View {
    @Bindable var store: StoreOf<Cat>
    
    @State var frameIndex = 0
    @State var animationTask: Task<Void, Never>?
    
    var body: some View {
        Image(store.type.frames[frameIndex], bundle: .module)
            .resizable()
            .scaledToFit()
            .onAppear(perform: startAnimation)
            .onDisappear(perform: stopAnimation)
            .onChange(of: store.withAnimation) {
                if store.withAnimation {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
    }
    
    func startAnimation() {
        guard store.withAnimation else { return }
        
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(store.animationInterval.value))
                guard !Task.isCancelled else { return }
                if frameIndex == store.type.frames.count - 1 {
                    frameIndex = 0
                    continue
                }
                frameIndex += 1
            }
        }
    }
    
    func stopAnimation() {
        animationTask?.cancel()
    }
}

extension CatType {
    var frames: [String] {
        switch self {
        case .onBall:
            makeFrames(name: "CatOnBallClear", count: 2)
        case .hasTimer:
            makeFrames(name: "CatHasTimer", count: 2)
        case .completeTimer:
            makeFrames(name: "CatHasTimerComplete", count: 2)
        case .pickUp:
            makeFrames(name: "CatPickUp", count: 2)
        }
    }
    
    private func makeFrames(name: String, count: Int) -> [String] {
        var frames: [String] = []
        for i in 1...count {
            frames.append("Cat/\(name)\(i)")
        }
        return frames
    }
}
