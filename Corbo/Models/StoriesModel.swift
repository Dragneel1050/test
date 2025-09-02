//
//  StortiesModel.swift
//  Corbo
//
//  Created by Agustín Nanni on 06/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Combine
import Foundation

@Observable
class StoriesModel {
    static let shared = StoriesModel()
    
    @ObservationIgnored
    let storiesPublisher = PassthroughSubject<StoryEvent, Never>()
    
    private(set) var storiesList: [storyWithEntities]? = nil
    
    func createStory(_ content: String, location: Location?, sessionId: Int64?, inChat: Bool?) async throws -> Int64? {
        let result = try await ApiModel.shared.createStory(content: content, location: location, sessionId: sessionId, inChat: inChat)
        Task{ @MainActor in
            self.storiesPublisher.send(StoryEvent(id: result.id, content: result.content, type: .created))
            prepareStoriesView()
        }
        return result.sessionId
    }
    
    func editStory(id: Int64, content: String) async throws -> storyWithEntities {
        let result = try await ApiModel.shared.editStory(id: id, content: content)
        Task{ @MainActor in
            self.storiesPublisher.send(StoryEvent(id: result.id, content: result.story?.content, type: .edited))
            prepareStoriesView()
        }
        return result
    }
    
    func deleteStory(id: Int64) async throws {
        try await ApiModel.shared.deleteStoryById(id: id)
        Task{ @MainActor in
            self.storiesPublisher.send(StoryEvent(id: id, content: nil, type: .deleted))
            prepareStoriesView()
        }
    }
    
    func prepareStoriesView() {
        Task { @MainActor in
            do {
                let response = try await ApiModel.shared.prepareStoriesPage()
                self.storiesList = response.storyList
            } catch let err {
                self.storiesList = []
                if case ApiErrors.RequestTimeout = err {
                    // Handle the timeout error
                    ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                } else {
                    AppLogs.defaultLogger.error("prepareStoriesView: \(err)")
                    ToastsModel.shared.notifyError(context: "StoriesModel.prepareStoriesView()", error: err)
                }
                
            }
        }
    }
}

enum StoryEventType {
    case created, edited, deleted
}

struct StoryEvent {
    let id: Int64
    let content: String?
    let type: StoryEventType
}
