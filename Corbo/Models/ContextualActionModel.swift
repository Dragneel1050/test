//
//  ContextMenuModel.swift
//  Corbo
//
//  Created by Agustín Nanni on 01/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class ContextualActionModel {
    static let shared = ContextualActionModel()
    
    let StoryCardContextualActionEvent = PassthroughSubject<UUID, Never>()
    @MainActor
    let MessageEventsPublisher = PassthroughSubject<MessageEvent, Never>()
    
    let keyboardHeightPublisher = PassthroughSubject<CGFloat, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
        .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
        .map { $0.cgRectValue.height }
        .eraseToAnyPublisher()
        .sink(receiveValue: { value in
            if value < 150 {
                self.keyboardHeightPublisher.send(CGFloat(0))
                return
            }
            
            self.keyboardHeightPublisher.send(value)
        })
        .store(in: &cancellables)
        
        NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillHideNotification)
        .sink(receiveValue: { _ in
            self.keyboardHeightPublisher.send(0)
        })
        .store(in: &cancellables)
    }
}
