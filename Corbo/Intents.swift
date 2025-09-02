//
//  Intents.swift
//  Corbo
//
//  Created by Agustín Nanni on 16/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import AppIntents

struct CreateStoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Intent.CreateStory.Name"


    static var description = IntentDescription("Intent.CreateStory.Description")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        HomeModel.shared.chatViewOpen = true
        return .result()
    }
}

struct CorboShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateStoryIntent(),
            phrases: ["Create \(.applicationName) story", "Create story on \(.applicationName)"],
            shortTitle: "Create story",
            systemImageName: "bubble")
    }
}
