//
//  Extension.swift
//  Corbo
//
//  Created by Agustín Nanni on 15/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import SwiftUI

struct EventsModifier: ViewModifier {
    let onAppearEvent: [AnalyticsEvent]
    
    func body(content: Content) -> some View {
        content
            .onAppear{
                for event in onAppearEvent {
                    EventsModel.shared.track(event)
                }
            }
    }
}

extension View {
    func trackOnAppear(@AnalyticsEventBuilder _ events: () -> [AnalyticsEvent]) -> some View {
        let modifier = EventsModifier(onAppearEvent: events())
        return self.modifier(modifier)
    }
    
    func withoutAnimation(action: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            action()
        }
    }
}

@resultBuilder struct AnalyticsEventBuilder {
    static func buildBlock(_ events: AnalyticsEvent...) -> [AnalyticsEvent] {
        events
    }
}
