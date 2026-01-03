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
    case think
}

struct CatView: View {
    @Bindable var store: StoreOf<Cat>
    
    @State var frameIndex = 0
    @State var animationTask: Task<Void, Never>?
    
    var body: some View {
        Image(safeFrame, bundle: .module)
            .resizable()
            .scaledToFit()
            .onAppear(perform: startAnimation)
            .onDisappear(perform: stopAnimation)
    }
    
    var frames: [String] {
        store.type.frames
    }
    
    var safeFrame: String {
        guard frames.count > frameIndex else {
            return store.type.frames[0]
        }
        return frames[frameIndex]
    }
    
    func startAnimation() {
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(store.animationInterval.value))
                guard !Task.isCancelled else { return }
                if frameIndex == frames.count - 1 {
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
            makeFrames(name: "CatOnBall", count: 2)
        case .hasTimer:
            makeFrames(name: "CatHasTimer", count: 2)
        case .completeTimer:
            makeFrames(name: "CatHasTimerComplete", count: 2)
        case .pickUp:
            makeFrames(name: "CatPickUp", count: 2)
        case .think:
            makeFrames(name: "CatThink", count: 3)
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
