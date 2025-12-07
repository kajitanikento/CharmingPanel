//
//  PanelContentView.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/06.
//

import SwiftUI

enum InputSource {
    case abc
    case hiragana
    
    static func of(_ name: String) -> Self {
        // TODO: 仮実装
        if name.lowercased().contains("us") || name.contains("英数") || name.lowercased().contains("abc") {
            return .abc
        }
        return .hiragana
    }
}

struct PanelContentView: View {
    static let size = CGSize(width: 80, height: 80)
    
    @ObservedObject var manager: InputSourceManager
    
    var currentInputSource: InputSource {
        .of(manager.currentName)
    }
    
    var body: some View {
        ZStack {
            VStack {
                Text(shortLabel)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                Text(manager.currentName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(textColor.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(backgroundColor.opacity(0.9))
        .clipShape(Circle())
        
        .shadow(radius: 6)
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
    PanelContentView(manager: .init())
}

extension View {
    
    @ViewBuilder
    func glassEffectIfAvailable() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: .capsule)
        } else {
            self
        }
    }
    
}
