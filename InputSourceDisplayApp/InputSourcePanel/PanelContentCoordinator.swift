//
//  PanelContentCoordinator.swift
//  InputSourceDisplayApp
//
//  Created by kajitani kento on 2025/12/07.
//

import Combine

@MainActor
final class PanelContentCoordinator: ObservableObject {
    enum Input {
        case hide
    }
    
    var inputTrigger: PassthroughSubject<Input, Never> = .init()
    
    func onSelectHide() {
        inputTrigger.send(.hide)
    }
}
