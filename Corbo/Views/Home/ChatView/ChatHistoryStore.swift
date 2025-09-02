//
//  ChatHistoryStore.swift
//  Corbo
//
//  Created by Agustín Nanni on 03/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation


@globalActor
actor ChatHistoryStore {
    static let shared = ChatHistoryStore()
    
    private let fileManager = FileManager.default
    private let historyFilePrefix = "chatHistory_"
    
    private func buildUrlForSessionId(_ sessionId: Int64) -> URL {
        let cacheUlr = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileName = historyFilePrefix + sessionId.description
        let fileUrl = cacheUlr.appending(path: fileName)
        
        return fileUrl
        
    }
    
    private func historyExists(sessionId: Int64) -> (Bool, URL) {
        let fileUrl = buildUrlForSessionId(sessionId)

        let exists = fileManager.fileExists(atPath: fileUrl.path(percentEncoded: false))
                
        return (exists, fileUrl)
    }
    
    private func interactionToChatElement(_ interaction: Interaction) -> [ChatElement]? {
        switch interaction.type {
            case .addStory:
                return [
                    ChatElement(type: .assistantMessage, text: assistantTextStrings.capturingStory.value, questionId: nil),
                    ChatElement(type: .userTranscript, text: interaction.input),
                    ChatElement(type: .assistantMessage, text: assistantTextStrings.storySuccess.value)
                ]
            case .askQuestion:
            if let payload = interaction.output as? QuestionInteractionOutput {
                    return [
                        ChatElement(type: .assistantMessage, text: assistantTextStrings.capturingQuestion.value),
                        ChatElement(type: .userTranscript, text: interaction.input, questionId: payload.data.questionId),
                        ChatElement(type: .assistantMessage, text: payload.data.data ?? "", entities: payload.data.entityList, questionId: payload.data.questionId, input: interaction.input)
                    ]
                }
            case .searchYourContacts:
            if let payload = interaction.output as? QuestionInteractionOutput {
                    return [
                        ChatElement(type: .assistantMessage, text: assistantTextStrings.searchContacts.value),
                        ChatElement(type: .userTranscript, text: interaction.input, questionId: payload.data.questionId),
                        ChatElement(type: .assistantMessage, text: payload.data.data ?? "", entities: payload.data.entityList, questionId: payload.data.questionId, input: interaction.input)
                    ]
                }
            case .unknown:
            if let payload = interaction.output as? QuestionInteractionOutput {
                    return [
                        ChatElement(type: .assistantMessage, text: assistantTextStrings.listening.value),
                        ChatElement(type: .userTranscript, text: interaction.input, questionId: payload.data.questionId),
                        ChatElement(type: .assistantMessage, text: payload.data.data ?? "", entities: payload.data.entityList, questionId: payload.data.questionId, input: interaction.input)
                    ]
                }
            case .searchYourStories:
            if let payload = interaction.output as? ListStoriesInteractionOutput {
                    return [
                        ChatElement(type: .assistantMessage, text: assistantTextStrings.searchContacts.value),
                        ChatElement(type: .userTranscript, text: interaction.input),
                        ChatElement(type: .storyList, storyListResponseData: payload.data, input: interaction.input)
                    ]
                }
            default:
                AppLogs.defaultLogger.warning("got unknown interaction type \(interaction.type?.rawValue ?? "nil")")
                return nil
            }
        
        return nil
    }
    
    func retrieveHistory(sessionId: Int64) async throws -> [ChatElement]? {
        /*
         let (exists, fileUrl) = historyExists(sessionId: sessionId)
         
         if exists {
             AppLogs.defaultLogger.debug("chat history cache hit for session id \(sessionId.formatted())")
             let data = try Data(contentsOf: fileUrl)
             let history = try JSONDecoder().decode([ChatElement].self, from: data)
             if isHistoryValid(history) {
                 return history
             } else {
                 try? fileManager.removeItem(at: fileUrl)
             }
             
             AppLogs.defaultLogger.warning("Empty history retrieved from cache")
         }
         */
        
        AppLogs.defaultLogger.debug("chat history cache miss for session id \(sessionId.formatted())")
        let data = try await ApiModel.shared.listSessionInteractions(id: sessionId)
        var result = [ChatElement]()
        for interaction in data.interactionList.reversed() {
            if let elements = interactionToChatElement(interaction) {
                result.append(contentsOf: elements)
            }
        }
                    
        if !result.isEmpty {
            saveHistory(sessionId: sessionId, history: result)
        }
        
        return result
    }
    
    func isHistoryValid(_ history: [ChatElement]) -> Bool {
        if history.isEmpty {
            return false
        }
        
        if history.first(where: { $0.text == nil }) != nil {
            return false
        }
        
        return true
    }
    
    func saveHistory(sessionId: Int64, history: [ChatElement]) {
        guard let data = try? JSONEncoder().encode(history) else {
            AppLogs.defaultLogger.error("saveHistory: unable to encode history data")
            return
        }
        
        let fileUrl = buildUrlForSessionId(sessionId)
        
        do {
            try data.write(to: fileUrl, options: [.atomic, .completeFileProtection])
        } catch let error {
            AppLogs.defaultLogger.error("saveHistory: \(error)")
        }
    }
}
