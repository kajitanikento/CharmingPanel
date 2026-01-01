//
//  EndWindowDrag.swift
//  CharmingPanelPackage
//
//  Created by kajitani kento on 2025/12/29.
//

import SwiftUI

extension View {
    
    @ViewBuilder
    func onEndWindowDrag(disable: Bool, perform action: @escaping () -> Void) -> some View {
        if disable {
            self
        } else {
            self.gesture(
                WindowDragGesture()
                    .onEnded { _ in
                        action()
                    }
            )
        }
    }
    
}
