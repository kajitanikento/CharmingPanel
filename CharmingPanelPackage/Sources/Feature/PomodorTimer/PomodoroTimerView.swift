//
//  PomodoroTimerView.swift
//  CharmingPanel
//
//  Created by kajitani kento on 2025/12/14.
//

import SwiftUI
import ComposableArchitecture

struct PomodoroTimerView: View {
    static let size: CGSize = .init(width: 100, height: 36)
    
    @Bindable var store: StoreOf<PomodoroTimer>
    
    var body: some View {
        if let timerText {
            timerText
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
    }
    
    var timerText: Text? {
        if store.isComplete {
            return Text("終わり")
        }
        guard let time = store.time else {
            return nil
        }
        return Text(timerInterval: time.startDate...time.endDate, countsDown: true, showsHours: false)
    }
    
    var backgroundColor: Color {
        if store.isComplete {
            return .orange
        }
        return .gray
    }
}
