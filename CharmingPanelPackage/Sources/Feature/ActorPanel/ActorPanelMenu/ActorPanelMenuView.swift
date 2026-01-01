//
//  ActorPanelMenuView.swift
//  CharmingPanelPackage
//
//  Created by kajitani kento on 2025/12/29.
//

import SwiftUI
import ComposableArchitecture

struct ActorPanelMenuView: View {
    nonisolated static let size = CGSize(width: 274 + 4, height: 210 + 4)
    
    @Bindable var store: StoreOf<ActorPanelMenu>
    
    @State var sliderValue: Int = 5
    
    var body: some View {
        VStack {
            timerMenu
            
//            settingMenu
            
            Spacer()
        }
        
    }
    
    // MARK: Timer menu
    
    var rows: [GridItem] = Array(repeating: .init(.fixed(44)), count: 2)
    
    var timerMenu: some View {
        menuBlock(
            "タイマー",
            ignoreContentHorizontalPadding: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                timerPresets
                timerHistory
            }
        }
    }
    
    var timerPresets: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(1...12, id: \.self) { baseNum in
                    timerStartButton(intervalMinute: baseNum * 5)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    var _history: [Int] {
        [
            25, 5
        ]
    }
    
    var timerHistory: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("最近の項目")
                .font(.title3.bold())
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(_history, id: \.self) { interval in
                        timerStartButton(
                            intervalMinute: interval,
                            backgroundColor: .orange
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    func timerStartButton(
        intervalMinute: Int,
        foregroundColor: Color = .white,
        backgroundColor: Color = .gray
    ) -> some View {
        Button(action: {
            store.send(.onStartTimer(intervalMinute: intervalMinute))
        }) {
            ZStack {
                backgroundColor
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(intervalMinute)")
                        .font(.title2)
                    Text("分")
                        .font(.caption)
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .clipShape(Circle())
    }
    
    var timerIntervalLabel: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("\(sliderValue)")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
            Text("分")
                .font(.system(size: 20))
        }
    }

    var timerControlButton: some View {
        Button(action: {
            // TODO: 開始/停止での制御
            store.send(.onStartTimer(intervalMinute: sliderValue))
        }) {
            // TODO: 開始/停止でアイコンと色を変える
            ZStack {
                Color.blue
                Image(systemName: "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18)
                    // play.fillの時に完全に中央だと視覚的にずれて見えるので少しずらしている
                    .offset(x: 2)
            }
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .clipShape(Circle())
    }
    
    // MARK: Other menu
    
    var settingMenu: some View {
        VStack {
            Text("hoge")
            Text("fuga")
        }
        .padding()
    }
    
    // MARK: Common
    
    func menuBlock<Content: View>(
        _ title: String,
        ignoreContentHorizontalPadding: Bool = false,
        content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            content()
                .padding(.horizontal, ignoreContentHorizontalPadding ? 0 : 16)
        }
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ZStack {
        // dummy window
        Color.blue
        
        ActorPanelMenuView(
            store: .init(initialState: ActorPanelMenu.State()) {
                ActorPanelMenu()
            }
        )
        .frame(width: ActorPanelMenuView.size.width, height: ActorPanelMenuView.size.height)
            .overlay(.black, in: RoundedRectangle(cornerRadius: 20).stroke(style: .init(lineWidth: 2, dash: [2, 4])))

    }
}
