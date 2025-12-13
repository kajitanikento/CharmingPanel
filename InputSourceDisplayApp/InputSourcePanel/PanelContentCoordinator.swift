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
        case toggleMovable(to: Bool)
    }
    
    var inputTrigger: PassthroughSubject<Input, Never> = .init()
    
    @Published var isMoving = true
    
    func onToggleMovable() {
        isMoving.toggle()
        inputTrigger.send(.toggleMovable(to: isMoving))
    }
    
    func onSelectHide() {
        inputTrigger.send(.hide)
    }
}
