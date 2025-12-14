//
//  CatFrameForwardView.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/07.
//

import SwiftUI

struct CatFrameForwardView: View {
    var type: CatType
    var size: CGSize
    var withAnimation: Bool
    
    @State var frameIndex = 0
    @State var animationTask: Task<Void, Never>?
    
    var body: some View {
        Image(type.frames[frameIndex])
            .resizable()
            .scaledToFit()
            .frame(width: size.width)
            .onAppear(perform: startAnimation)
            .onDisappear(perform: stopAnimation)
            .onChange(of: withAnimation) {
                if withAnimation {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
    }
    
    func startAnimation() {
        guard withAnimation else { return }
        
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                if frameIndex == type.frames.count - 1 {
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

extension CatFrameForwardView {
    enum CatType {
        case onBall
        case pickUp
        
        var frames: [String] {
            switch self {
            case .onBall:
                makeFrames(name: "CatOnBallClear", count: 2)
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
}
