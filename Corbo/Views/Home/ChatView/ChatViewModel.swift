//
//  ChatViewModel.swift
//  Corbo
//
//  Created by Agustín Nanni on 17/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

enum ChatViewModes {
    case Text, Voice
}

enum ScrollTypes {
    case bottom, top
}

@MainActor
@Observable
class ChatViewModel {
    var firstBubbleVariant: ChatBubbleVariants = .assistant
    var lastIntentInference: CNNModelResultTypes? = nil
    var working = false
    var chatHistory: [ChatElement]
    var streamingAnswerContent = ""
    var textModeText = "" {
        didSet {
            self.textUpdatesPublisher.send(textModeText)
        }
    }
    var showLeavingConfirmation = false
    var currentMode = ChatViewModes.Voice
    var activeContextMenuElement: ContextChatElement? = nil
    var showingCurrentStoryPreview = false
    var currentStoryText = ""
    var recording: Bool
    var messagesWorking = false
    var session: Session?
    var showSessionHeaderContextMenu = false
    var scrollPublisher = PassthroughSubject<ScrollTypes, Never>()
    var textUpdatesPublisher = PassthroughSubject<String, Never>()
    var impactPublisher = PassthroughSubject<Bool, Never>()
    var cancellables = [AnyCancellable]()
    var startDate = Date.now
    var textModeFocus = false
    var assistantTextBubbleId: UUID?
    var userTranscriptId: UUID?
    var currentAnswerId: UUID?
    var showSessionRenameSheet = false
    
    private let impactGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    init(chatViewOpen: Binding<Bool>, messages: [ChatElement]? = nil, session: Session? = nil) {
        let defaultMode = ConfigModel.shared.findInputMode()
        switch defaultMode {
        case .Voice:
            self.currentMode = .Text
        case .Text:
            self.currentMode = .Text
        }
        self.recording = {
            session == nil && defaultMode == .Voice
        }()
        self.chatHistory = [ChatElement]()
        if let messages = messages {
            chatHistory.append(contentsOf: messages)
        }
        LocationModel.shared.updateLocation()
        AppLogs.defaultLogger.info("chat view model init")
        if let session = session {
            self.messagesWorking = true
            Task {
                do {
                    if let history = try await ChatHistoryStore.shared.retrieveHistory(sessionId: session.id!) {
                        self.chatHistory = history
                        self.session = session
                        self.messagesWorking = false
                    } else {
                        SpeechReconitionModel.shared.reset()
                        HomeModel.shared.chatViewOpen = false
                        ToastsModel.shared.displayMessage(text: String("ChatViewModel.SessionHistoryError"))
                    }
                } catch let err {
                    SpeechReconitionModel.shared.reset()
                    HomeModel.shared.chatViewOpen = false
                    
                    if case ApiErrors.RequestTimeout = err {
                        // Handle the timeout error
                        ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                    } else {
                        AppLogs.defaultLogger.error("Error getting chat history \(err)")
                        ToastsModel.shared.notifyError(context: "ChatViewModel.init()", error: err )
                    }
                }
            }
        } else {
            switch defaultMode {
            case .Voice:
                handleListeningStarted()
            case .Text:
                handleEnableTextMode()
            }
        }
        
        SpeechReconitionModel.shared.intents.sink(receiveValue: {intent in
            print("Intents", intent)
            self.lastIntentInference = intent
            self.setAssistantText(self.assistantBubbleText(intent))
        })
        .store(in: &cancellables)
        
        self.textUpdatesPublisher
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .sink(receiveValue: { text in
                SpeechReconitionModel.shared.updateIntent(text)
                self.scrollPublisher.send(.bottom)
            })
            .store(in: &cancellables)
        
        /*
         SpeechReconitionModel.shared.transcripts.sink(receiveValue: { transcript in
         print("transcript", transcript)
         if !transcript.isEmpty {
         if let id = self.userTranscriptId {
         self.userTranscriptText = transcript
         self.sendMessageEvent(MessageEvent(messageId: id, text: self.userTranscriptText))
         self.sendScrollToBottomEvent()
         }
         }
         })
         .store(in: &cancellables)
         */
        
        impactPublisher
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .sink(receiveValue: { _ in
                self.impactGenerator.impactOccurred()
            })
            .store(in: &cancellables)
    }
    
    func handleLeave() {
        if !textModeText.isEmpty && currentMode == .Voice {
            showLeavingConfirmation = true
            return
        }
        
        doLeave()
    }
    
    func doLeave() {
        SpeechReconitionModel.shared.reset()
        HomeModel.shared.chatViewOpen = false
        if let session = self.session {
            Task {
                await ChatHistoryStore.shared.saveHistory(sessionId: session.id!, history: self.chatHistory)
            }
        }
        
        EventsModel.shared.track(ChatSessionEnded(dateStart: self.startDate, dateEnd: Date.now))
    }
    
    func setAssistantText(_ text: String) {
        if let id = self.assistantTextBubbleId {
            Task{ @MainActor in
                sendMessageEvent(MessageEvent(messageId: id, text: text))
            }
        }
    }
    
    func sendMessageEvent(_ event: MessageEvent) {
        Task{ @MainActor in
            ContextualActionModel.shared.MessageEventsPublisher.send(event)
        }
    }
    
    func sendScrollToBottomEvent() {
        Task{ @MainActor in
            self.scrollPublisher.send(.bottom)
        }
    }
    
    func sendScrollToTopEvent() {
        Task{ @MainActor in
            self.scrollPublisher.send(.top)
        }
    }
    
    func handleEnableTextMode() {
        self.currentMode = .Text
        self.textModeFocus = true
        SpeechReconitionModel.shared.reset()
        if assistantTextBubbleId == nil {
            self.assistantTextBubbleId = UUID()
            self.chatHistory.append(ChatElement(id: self.assistantTextBubbleId, type: .assistantMessage, text: assistantTextStrings.textModePrompt.value))
        }
        
        if let userTranscriptId = self.userTranscriptId {
            self.userTranscriptId = nil
            self.chatHistory = self.chatHistory.filter({ $0.id != userTranscriptId })
        }
    }
    
    func handlePaste() {
        handleEnableTextMode()
        let pasteboard = UIPasteboard.general
        if let text = pasteboard.string {
            self.textModeText += text
        }
    }
    
    func assistantBubbleText(_ intent: CNNModelResultTypes?) -> String {
        switch intent {
        case .addStory:
            return assistantTextStrings.capturingStory.value
        case .askQuestion:
            return assistantTextStrings.capturingQuestion.value
        case .searchYourContacts:
            return assistantTextStrings.searchContacts.value
        case .unknown:
            if currentMode == .Text {
                return assistantTextStrings.textModePrompt.value
            } else {
                return assistantTextStrings.listening.value
            }
        case .searchYourStories:
            return assistantTextStrings.searchYourStories.value
        case nil:
            if currentMode == .Text {
                return assistantTextStrings.textModePrompt.value
            } else {
                return assistantTextStrings.listening.value
            }
        }
    }
    
    func openElementContextualMenu(_ elem: ChatElement, anchor: Anchor<CGRect>) {
        if elem.questionId != nil {
            self.activeContextMenuElement = ContextChatElement(elem: elem, anchor: anchor)
        }
    }
    
    func closeElementContextualMenu() {
        self.activeContextMenuElement = nil
    }
    
    func searchStories(_ prompt: String) async {
        do {
            let result = try await ApiModel.shared.searchStories(input: prompt, sessionId: session?.id)
            self.handleSessionId(result.sessionId)
            self.addElementToList(ChatElement(type: .storyList, storyListResponseData: storyListResponseData(storyList: result.storyList, prompt: prompt)))
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("searchStories: \(err)")
                ToastsModel.shared.notifyError(context: "ChatViewModel.searchStories()", error: err )
            }
        }
    }
    
    
    func handleCreateStory(_ whisperText: String) {
        self.currentStoryText = whisperText
        self.showingCurrentStoryPreview = true
        self.chatHistory.append(ChatElement(type: .assistantMessage, text: assistantTextStrings.readyToSaveStory.value))
        SpeechReconitionModel.shared.reset()
    }
    
    func createStory(_ content: String) async {
        do {
            self.working = true
            let sessionId = try await StoriesModel.shared.createStory(content, location: LocationModel.shared.getLastLocation(), sessionId: session?.id, inChat: true)
            self.handleSessionId(sessionId)
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("createStory: \(err)")
                ToastsModel.shared.notifyError(context: "ChatViewModel.createStory()", error: err )
            }
        }
    }
    
    func reaskQuestion(_ questionId: Int64) async {
        if let questionText = self.chatHistory.first( where: { $0.questionId == questionId && $0.input != nil })?.input {
            var isContactsSearch = false
            if let intent = try? SpeechReconitionModel.shared.cnn.predict(questionText) {
                if intent.strongest() == .searchYourContacts {
                    isContactsSearch = true
                }
            }
            
            self.chatHistory.append(ChatElement(id: self.currentAnswerId, type: .userTranscript, text: questionText))
            await askQuestion(questionText, searchContacts: isContactsSearch)
            sendScrollToBottomEvent()
        }
    }
    
    func askQuestion(_ question: String, searchContacts: Bool) async {
        do {
            self.currentAnswerId = UUID()
            self.chatHistory.append(ChatElement(id: self.currentAnswerId, type: .assistantMessage, text: nil, input: question))
            try await ApiModel.shared.askWithStream(question: question, sessionId: session?.id, searchContacts: searchContacts, chunkHandler: handleResponseChunk)
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("askQuestion: \(err)")
                ToastsModel.shared.notifyError(context: "ChatViewModel.askQuestion()", error: err )
            }
        }
    }
    
    func handleCheckmark() {
        self.working = true
        self.assistantTextBubbleId = nil
        Task {
            await createStory(currentStoryText)
            EventsModel.shared.track(StoryCreated(source: "Chat view (Voice)"))
            await MainActor.run{
                self.addElementToList(ChatElement(type: .assistantMessage, text: assistantTextStrings.storySuccess.value))
                self.currentStoryText = ""
                self.showingCurrentStoryPreview = false
                self.working = false
            }
        }
        
    }
    
    func handleResponseChunk(_ chunk: askWithStreamChunkResponse) async -> Void {
        if let tokens = chunk.data {
            self.streamingAnswerContent += tokens
            sendMessageEvent(MessageEvent(messageId: self.currentAnswerId!, text: self.streamingAnswerContent))
        }
        
        if let questionId = chunk.questionId {
            sendMessageEvent(MessageEvent(messageId: self.currentAnswerId!, text: self.streamingAnswerContent, entities: chunk.entityList, questionId: questionId))
            self.currentAnswerId = nil
            self.streamingAnswerContent = ""
        }
        
        if let sessionId = chunk.sessionId {
            self.handleSessionId(sessionId)
        }
        
        self.impactPublisher.send(true)
    }
    
    func startListening() {
        self.currentMode = .Voice
        self.textModeText = ""
        
        Task.detached{
            SpeechReconitionModel.shared.startTranscribingAndRecording()
            await self.handleListeningStarted()
        }
    }
    
    private func handleListeningStarted() {
        self.recording = true
        if self.assistantTextBubbleId == nil {
            self.assistantTextBubbleId = UUID()
            self.chatHistory.append(ChatElement(id: self.assistantTextBubbleId, type: .assistantMessage, text: assistantTextStrings.listening.value))
        }
        if self.userTranscriptId == nil {
            self.userTranscriptId = UUID()
            self.chatHistory.append(ChatElement(id: self.userTranscriptId, type: .userTranscript, text: ""))
        }
        
        self.lastIntentInference = nil
    }
    
    func iconColor() -> Color {
        if working {
            .iconDisabled
        } else {
            .chatPrimary
        }
    }
    
    func handleTextCheckmark() {
        if textModeText.isEmpty {
            AppLogs.defaultLogger.warning("createStoryFromTextInput: checkmark tap w/o text")
            return
        }
        
        self.chatHistory.append(ChatElement(type: .userTranscript, text: textModeText))
        let text = textModeText
        self.working = true
        self.assistantTextBubbleId = nil
        Task{
            self.currentStoryText = ""
            self.textModeText = ""
            self.showingCurrentStoryPreview = false
            await handleIntentAction(text: text, isText: true)
            self.working = false
            self.assistantTextBubbleId = UUID()
            self.chatHistory.append(ChatElement(id: self.assistantTextBubbleId, type: .assistantMessage, text: assistantTextStrings.textModePrompt.value))
        }
    }
    
    func handleSessionId(_ id: Int64?) {
        guard id != nil else {
            AppLogs.defaultLogger.warning("Got nil session id!!")
            return
        }
        
        if self.session == nil {
            self.session = Session(id: id, userAccountId: nil, title: nil, createdTime: nil)
        } else {
            if session?.id == id {
                return
            } else {
                AppLogs.defaultLogger.warning("Got a different session id from the one that was already set!!")
                return
            }
        }
        
    }
    
    func handlePlus(_ whisperText: String) {
        self.currentStoryText += " " + whisperText
        self.setAssistantText(assistantTextStrings.readyToSaveStory.value)
        self.showingCurrentStoryPreview = true
        SpeechReconitionModel.shared.reset()
    }
    
    func handleCenterButtonTap() {
        if self.working{
            return
        }
        
        if self.recording {
            self.assistantTextBubbleId = nil
            self.working = true
            self.recording = false
            EventsModel.shared.track(ChatInteraction(type: lastIntentInference))
            Task{
                let whisperText = try await SpeechReconitionModel.shared.stopRecordingAndTranscribeUsingWhisper().text
                if let userTranscriptId = userTranscriptId {
                    self.sendMessageEvent(MessageEvent(messageId: userTranscriptId, text: whisperText))
                }
                
                SpeechReconitionModel.shared.reset()
                await MainActor.run{
                    self.userTranscriptId = nil
                }
                if currentStoryText.isEmpty {
                    await handleIntentAction(text: whisperText, isText: false)
                } else {
                    handlePlus(whisperText)
                }
                self.working = false
            }
            
        } else {
            if self.assistantTextBubbleId == nil {
                self.assistantTextBubbleId = UUID()
                self.chatHistory.append(ChatElement(id: self.assistantTextBubbleId, type: .assistantMessage, text: assistantTextStrings.listening.value))
            }
            if self.userTranscriptId == nil {
                self.userTranscriptId = UUID()
                self.chatHistory.append(ChatElement(id: self.userTranscriptId, type: .userTranscript, text: ""))
            }
            
            if showingCurrentStoryPreview {
                self.showingCurrentStoryPreview = false
            }
            
            self.startListening()
        }
    }
    
    func handleIntentAction(text: String, isText: Bool) async {
        switch lastIntentInference {
        case .addStory:
            if isText {
                await createStory(text)
                await MainActor.run{
                    self.chatHistory.append(ChatElement(type: .assistantMessage, text: assistantTextStrings.storySuccess.value))
                }
            } else {
                handleCreateStory(text)
                AppLogs.defaultLogger.info("handleCenterButtonTap: addStory")
            }
        case .askQuestion:
            AppLogs.defaultLogger.info("handleCenterButtonTap: question")
            await askQuestion(text, searchContacts: false)
        case .searchYourContacts:
            AppLogs.defaultLogger.info("handleCenterButtonTap: contact")
            await askQuestion(text, searchContacts: true)
        case .unknown:
            AppLogs.defaultLogger.info("handleCenterButtonTap: unknown \(text)")
            await askQuestion(text, searchContacts: false)
        case .searchYourStories:
            AppLogs.defaultLogger.info("handleCenterButtonTap: searchYourStories \(text)")
            await searchStories(text)
        case nil:
            AppLogs.defaultLogger.info("handleCenterButtonTap: defaultUnknown \(text)")
            await askQuestion(text, searchContacts: false)
        }
    }
    
    func addElementToList(_ elem: ChatElement) {
        withAnimation{
            self.chatHistory.append(elem)
            if let sessionId = self.session?.id {
                Task {
                    await ChatHistoryStore.shared.saveHistory(sessionId: sessionId, history: self.chatHistory)
                }
            }
        }
    }
    
    func deleteSession() async {
        await NetworkViewModel.shared.deleteSession(self.session!)
        self.session = nil
        HomeModel.shared.chatViewOpen = false
    }
}

enum ChatElementType: String, Codable {
    case assistantMessage, userTranscript, storyList
}

struct ChatElement: Identifiable, Hashable, Codable {
    static func == (lhs: ChatElement, rhs: ChatElement) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    let id: UUID
    let type: ChatElementType
    let text: String?
    let storyListResponseData: storyListResponseData?
    let entityList: [wordEntity]?
    let questionId: Int64?
    let input: String?
    
    init(id: UUID? = nil, type: ChatElementType, text: String? = nil, storyListResponseData: storyListResponseData? = nil, entities: [wordEntity]? = nil, questionId: Int64? = nil, input: String? = nil) {
        self.id = {
            if id == nil {
                UUID()
            } else {
                id!
            }
        }()
        self.text = text
        self.type = type
        self.storyListResponseData = storyListResponseData
        self.entityList = entities
        self.questionId = questionId
        self.input = input
    }
}


struct storyListResponseData: Hashable, Codable {
    static func == (lhs: storyListResponseData, rhs: storyListResponseData) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(storyList: [storyWithEntities], prompt: String) {
        self.id = UUID()
        self.storyList = storyList
        self.prompt = prompt
    }
    
    let id: UUID
    let storyList: [storyWithEntities]
    let prompt: String
}

enum assistantTextStrings {
    case listening
    case textModePrompt
    case capturingStory
    case capturingQuestion
    case searchContacts
    case searchYourStories
    case storySuccess
    case storyAdding
    case readyToSaveStory
    
    var value: String {
        switch self {
        case .listening:
            return String(localized: "ChatViewModel.Prompts.Listening")
        case .textModePrompt:
            return String(localized: "ChatViewModel.Prompts.TextMode")
        case .capturingStory:
            return String(localized: "ChatViewModel.Prompts.StoryCapture")
        case .capturingQuestion:
            return String(localized: "ChatViewModel.Prompts.QuestionCapture")
        case .searchContacts:
            return String(localized: "ChatViewModel.Prompts.ContactSearch")
        case .searchYourStories:
            return String(localized: "ChatViewModel.Prompts.StorySearch")
        case .storySuccess:
            return String(localized: "ChatViewModel.Prompts.StorySuccess")
        case .storyAdding:
            return String(localized: "ChatViewModel.Prompts.StoryAdding")
        case .readyToSaveStory:
            return String(localized: "ChatViewModel.Prompts.ReadyToSave")
        }
    }
}

struct ContextChatElement {
    let elem: ChatElement
    let anchor: Anchor<CGRect>
}

struct MessageEvent {
    let messageId: UUID
    let text: String
    let entities: [wordEntity]?
    let questionId: Int64?
    
    init(messageId: UUID, text: String, entities: [wordEntity]? = nil, questionId: Int64? = nil) {
        self.messageId = messageId
        self.text = text
        self.entities = entities
        self.questionId = questionId
    }
}
