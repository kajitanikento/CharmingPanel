//
//  ActorPanelMenuView.swift
//  CharmingPanelPackage
//
//  Created by kajitani kento on 2025/12/29.
//

import SwiftUI
import ComposableArchitecture

struct ActorPanelMenuView: View {
    @Bindable var store: StoreOf<ActorPanelMenu>
    // アクションを実行した後にメニューが消える前に表示が切り替わらないように固定値のStateを保持している
    var stateForDisplay: ActorPanelMenu.State
    
    init(store: StoreOf<ActorPanelMenu>) {
        self.store = store
        self.stateForDisplay = store.state
    }
    
    var body: some View {
        content
    }
    
    var content: some View {
        VStack(spacing: 8) {
            timerMenu
            menuTiles
            
            Spacer()
        }
        .frame(width: menuMaxWidth)
        .padding(4)
    }
    
    // MARK: Timer menu
    
    var timerMenu: some View {
        menuBlock(
            "タイマー",
            ignoreContentHorizontalPadding: true
        ) {
            if let startedTimerTime = stateForDisplay.startedTimerTime {
                timerStopContent(startedTimerTime: startedTimerTime)
            } else {
                timerStartContent
            }
        }
    }
    
    var timerStartContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            timerPresets
            
            if stateForDisplay.timeIntervalMinuteHistory.isNotEmpty {
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
    
    var timerHistory: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("最近の項目")
                .font(.title3.bold())
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stateForDisplay.timeIntervalMinuteHistory, id: \.self) { interval in
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
        circleButton(
            action: {
                store.send(.onClickStartTimer(time: .init(startDate: .now, intervalMinute: intervalMinute)))
            },
            label: {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(intervalMinute)")
                        .font(.title2)
                    Text("分")
                        .font(.caption)
                }
            },
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor
        )
    }
    
    func timerStopContent(startedTimerTime: PomodoroTimer.PomodoroTime) -> some View {
        HStack(spacing: 12) {
            timerStopButton
            Text(timerInterval: startedTimerTime.timeInterval, showsHours: false)
                .font(.title2.bold().monospaced())
                .foregroundStyle(.gray)
            
        }
        .padding(.horizontal, 16)
    }
    
    var timerStopButton: some View {
        circleButton(
            action: {
                store.send(.onClickStopTimer)
            },
            label: {
                Image(systemName: "stop.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14)
            },
                   foregroundColor: .white,
            backgroundColor: .blue
        )
    }
    
    // MARK: Menu tile
    
    var menuTiles: some View {
        HStack {
            LazyVGrid(columns: Array(repeating: .init(), count: tileColumnCount), alignment: .leading, spacing: 8) {
                hidePanelTile
                quitAppTile
            }
            
            Spacer(minLength: 0)
        }
    }
    
    var hidePanelTile: some View {
        menuTile(action: {
            store.send(.onClickHidePanel)
        }) {
            Image(systemName: "eye.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
        }
        .help("パネルを非表示")
    }
    
    var quitAppTile: some View {
        menuTile(
            action: {
                store.send(.onClickQuitApp)
            },
            foregroundColor: .white,
            backgroundColor: .red
        ) {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 16)
        }
        .help("アプリを終了")
    }
    
    var tileColumnCount: Int { 4 }
    var tileSpacing: CGFloat { 8 }
    var tileWidth: CGFloat {
        menuMaxWidth / CGFloat(tileColumnCount) - tileSpacing * CGFloat(tileColumnCount - 1) / CGFloat(tileColumnCount)
    }
    func menuTile<Content: View>(
        action: @escaping () -> Void,
        foregroundColor: Color = .black,
        backgroundColor: Color = .white,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Button(action: action) {
            ZStack {
                backgroundColor
                
                content()
            }
            .frame(width: tileWidth, height: tileWidth)
            .foregroundStyle(foregroundColor)
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: Common
    
    var menuMaxWidth: CGFloat {
        256
    }
    
    func menuBlock<Content: View>(
        _ title: String,
        ignoreContentHorizontalPadding: Bool = false,
        @ViewBuilder content: @escaping () -> Content
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
    
    func circleButton<Label: View>(
        action: @escaping () -> Void,
        label: @escaping () -> Label,
        foregroundColor: Color = .white,
        backgroundColor: Color = .gray
    ) -> some View {
        Button(action: action) {
            ZStack {
                backgroundColor
                
                label()
            }
            .foregroundStyle(foregroundColor)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .clipShape(Circle())
    }
}

#Preview {
    ZStack {
        // dummy window
        Color.blue
        
        ActorPanelMenuView(
            store: .init(initialState: ActorPanelMenu.State(
                timeIntervalMinuteHistory: [5, 10]
            )) {
                ActorPanelMenu()
            }
        )
    }
}
