//
//  MessageListView.swift
//  Corbo
//
//  Created by Agustín Nanni on 17/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct MessageListView: View {
    @Binding var model: ChatViewModel
    @FocusState private var focused: Bool
    @State private var messageBounds: [UUID: Anchor<CGRect>]? = nil
    @State private var messageListHeight = CGFloat.zero
    
    var body: some View {
        GeometryReader{ topGeo in
            ScrollView(showsIndicators: false){
                ScrollViewReader{ reader in
                    VStack{
                        Color.clear.frame(width: 50, height: 1)
                            .id(startId)
                        VStack{
                            ForEach(model.chatHistory, id: \.id) { elem in
                                ChatElementView(elem: elem, onAssistantMessageLongPress: handleOpenMessageContextMenu)
                            }
                            
                        }.background{
                            GeometryReader{ listReader in
                                Color.clear.onAppear{
                                    messageListHeight = listReader.size.height
                                }
                                .onChange(of: model.chatHistory, { _, _ in
                                    messageListHeight = listReader.size.height
                                })
                            }
                        }
                        if model.currentMode == .Text {
                            ChatTextField(model: $model, focused: $focused, containerGeometry: topGeo, messageListHeight: $messageListHeight)
                        }
                        if model.session == nil && !model.working && !model.showingCurrentStoryPreview && model.currentMode != .Text {
                            Text("MessageListView.PromptExamples")
                                .font(Theme.questionsSelectionSelected)
                                .foregroundStyle(Color.textPrimary)
                        }
                        Color.clear.frame(width: 50, height: 1)
                            .id(endId)
                    }
                    .padding(.top)
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        if model.showSessionHeaderContextMenu {
                            model.showSessionHeaderContextMenu = false
                        }
                    }
                    .onReceive(model.scrollPublisher.throttle(for: .milliseconds(200), scheduler: RunLoop.main, latest: true), perform: { type in
                        switch type {
                        case .bottom:
                            reader.scrollTo(endId)
                        case .top:
                            reader.scrollTo(startId)
                        }
                    })
                }
            }
            .onTapGesture {
                focused = true
            }
            .scrollDismissesKeyboard(.immediately)
            .onPreferenceChange(ChatBubbleSizePreferences.self) { value in
                messageBounds = value
            }
        }
    }
    
    @MainActor
    func handleOpenMessageContextMenu(_ elem: ChatElement) {
        if let anchor = self.messageBounds?[elem.id] {
            withAnimation(.interpolatingSpring){
                model.openElementContextualMenu(elem, anchor: anchor)
            }
        }
    }
}

fileprivate let startId = "startId"
fileprivate let endId = "endId"
fileprivate let currentTranscriptFieldId = "currentTranscriptFieldId"

fileprivate struct ChatTextField: View {
    @State private var minLines = 20
    @Binding var model: ChatViewModel
    @FocusState.Binding var focused: Bool
    var containerGeometry: GeometryProxy
    @Binding var messageListHeight: CGFloat
    
    var body: some View {
        TextField("", text: $model.textModeText, axis: .vertical)
            .lineLimit(minLines...10000)
            .disabled(model.currentMode == .Voice)
            .focused($focused)
            .onChange(of: model.textModeFocus) { old, new in
                focused = new
            }
            .onAppear{
                focused = model.textModeFocus
            }
            .font(Theme.chatTextTranscript)
            .foregroundStyle(
                model.working ?
                Color.chatTextThinking : Color.chatTextTranscript
            )
            .onChange(of: model.currentMode, { _, new in
                focused = new == .Text
            })
            .onChange(of: focused, { _, _ in
                updateMinLines()
            })
            .onChange(of: messageListHeight, {
                updateMinLines()
            })
            .onReceive(ContextualActionModel.shared.keyboardHeightPublisher, perform: { value in
                updateMinLines(keyboardHeight: value)
            })
            .onAppear{
                updateMinLines()
            }
    }
    
    func updateMinLines(keyboardHeight : CGFloat = 0) {
        let lineHeight = CGFloat(25)
        
        if messageListHeight > (containerGeometry.size.height * 0.8) {
            minLines = Int(floor((containerGeometry.size.height * 0.3) / lineHeight))
        } else {
            if keyboardHeight > 0 {
                let linesInKeyboardHeight = Int(floor(keyboardHeight / lineHeight))
                minLines = Int(floor(containerGeometry.size.height - messageListHeight) / lineHeight) - linesInKeyboardHeight
            } else {
                minLines = Int(floor(containerGeometry.size.height - messageListHeight) / lineHeight)
            }
        }
    }
}


struct ChatElementView: View {
    let elem: ChatElement
    let onAssistantMessageLongPress: (_ elem: ChatElement) -> Void
    
    var body: some View {
        switch elem.type {
        case .assistantMessage:
            ChatBubble(id: elem.id, questionId: elem.questionId, text: elem.text ?? "", elemType: elem.type, variant: .assistant, entities: elem.entityList, onLongPress: onAssistantMessageLongPress)
        case .userTranscript:
            ChatBubble(id: elem.id, questionId: elem.questionId, text: elem.text ?? "", elemType: elem.type, variant: .user, entities: elem.entityList, onLongPress: onAssistantMessageLongPress)
        case .storyList:
            StoryListView(storyList: elem.storyListResponseData!)
        }
    }
}


#Preview {
    MessageListView(model: Binding.constant(
        ChatViewModel(chatViewOpen: .constant(true),
                      messages: [
                        ChatElement(type: .userTranscript, text: "This is a question"),
                        ChatElement(type: .assistantMessage, text: "This is an answer")
                      ])))
    .background{
        Background()
    }
}
