//
//  InputSourceDisplayAppApp.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/11/29.
//

import SwiftUI

@main
struct InputSourceDisplayAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Source Indicator")
                    .font(.headline)
                Text("メニューバーのキーボードアイコンから表示を切り替えられます。")
                    .font(.caption)
            }
            .padding()
            .frame(width: 300)
        }
    }
}
