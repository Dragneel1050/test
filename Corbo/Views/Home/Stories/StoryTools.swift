//
//  StoryTools.swift
//  Corbo
//
//  Created by Agustín Nanni on 10/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

class StoryTools {
    static func createdText(dateCreated: Date) -> String {
        let secondsInDay = Double(3600 * 24)
        let timeSinceCreation = dateCreated.timeIntervalSinceNow
        
        if timeSinceCreation.magnitude > secondsInDay {
            return dateCreated.formatted()
        } else {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.zeroFormattingBehavior = .dropAll
            formatter.allowedUnits = [.hour, .minute]
            
            let formatted = formatter.string(from: TimeInterval(floatLiteral: timeSinceCreation.magnitude))
            if let interval = formatted {
                return "\(interval) ago"
            } else {
                return dateCreated.formatted()
            }
        }
    }
    
    @ViewBuilder
    static func buildCardText(content: String, storyId: Int64, entityList: [wordEntity]?) -> some View {
        if entityList != nil && !entityList!.isEmpty {
            TextWithEntities(text: content, entities: entityList!, storyId: storyId)
                .font(Theme.textStories)
                .foregroundStyle(.textPrimary)
        } else {
            Text(.init(content))
                .font(Theme.textStories)
                .foregroundStyle(.textPrimary)
        }
    }
}
