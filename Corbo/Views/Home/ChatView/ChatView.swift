//

import SwiftUI
import Combine

struct ChatView: View {
    @Binding var chatViewOpen: Bool
    @State private var firstTime = false
    let buttonBounds: CGRect
    let globalBounds: CGRect
    
    @State private var model: ChatViewModel
    
    @MainActor
    init(chatViewOpen: Binding<Bool>, buttonBounds: CGRect, globalBounds: CGRect) {
        self._chatViewOpen = chatViewOpen
        self.buttonBounds = buttonBounds
        self.globalBounds = globalBounds
        self.model = HomeModel.shared.chatViewModel ?? ChatViewModel(chatViewOpen: .constant(true))
    }
    
    var body: some View {
        ZStack{
            AppProgressView()
                .opacity(model.messagesWorking ? 1 : 0)
            VStack(spacing: 0){
                VStack(spacing: 0){
                    if model.session?.title != nil {
                        SessionHeader(session: model.session!, model: $model)
                            .zIndex(100)
                    }
                    MessageListView(model: $model)
                        .opacity(model.messagesWorking ? 0 : 1)
                        .onTapGesture {
                            model.textModeFocus = true
                        }
                        .padding(.top)
                }
                Spacer()
                ChatViewBottomControls(model: $model)
            }
            .onAppear{
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear{
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .ignoresSafeArea(edges: .bottom)
            .padding(.top, model.currentMode == .Text ? 10 : 0)
            .blur(radius: model.activeContextMenuElement != nil ? 5 : 0)
            .disabled(model.activeContextMenuElement != nil)
            .contentShape(Rectangle())
            if let contextMenuElem = model.activeContextMenuElement {
                ChatElemContextMenuView(dismiss: model.closeElementContextualMenu, elem: contextMenuElem, options: buildContextOptions(contextMenuElem)
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        .contentShape(Rectangle())
        .onTapGesture {
            if model.showSessionHeaderContextMenu {
                model.showSessionHeaderContextMenu = false
            }
        }
        .background{
            if model.currentMode == .Voice {
                ChatPanelBorder(buttonBounds: buttonBounds, globalBounds: globalBounds)
                    .stroke(.chatPrimary, style: StrokeStyle(lineWidth: 3, lineJoin: .miter))
                    .blur(radius: model.activeContextMenuElement != nil ? 5 : 0)
            } else {
                ChatPanelBorderText(globalBounds: globalBounds)
                    .stroke(.chatPrimary, style: StrokeStyle(lineWidth: 3, lineJoin: .miter))
                    .padding(.top)
                    .blur(radius: model.activeContextMenuElement != nil ? 5 : 0)
            }
        }
        .onAppear{
            if !model.working && !firstTime && model.recording {
                self.firstTime = true
                model.startListening()
            }
        }
        .confirmationDialog("ChatView.LeavingWarning", isPresented: $model.showLeavingConfirmation, titleVisibility: .visible, actions: {
            Button("ChatView.Leave", role: .destructive) {
                model.doLeave()
            }
            Button("ChatView.Cancel", role: .cancel) {
                model.showLeavingConfirmation = false
            }
        })
        .sheet(isPresented: $model.showSessionRenameSheet, content: {
            if let title = model.session?.title {
                ZStack{
                    Color.surfacePanel
                        .ignoresSafeArea()
                    RenameSessionTray(name: title, sessionId: model.session!.id!, model: $model)
                }
                .presentationDetents([.height(250)])
            }
        })
    }
    
    func buildContextOptions(_ contextMenuElem: ContextChatElement) -> [ContextMenuAction] {
        switch contextMenuElem.elem.type {
        case .assistantMessage:
            return [
                ButtonContextMenuAction(label: String(localized: "ChatView.Context.Save"), action: {
                    let _ = try await StoriesModel.shared.createStory(contextMenuElem.elem.text ?? "", location: LocationModel.shared.getLastLocation(), sessionId: nil, inChat: false)
                    EventsModel.shared.track(StoryCreated(source: "Save as story"))
                }),
                ButtonContextMenuAction(label: String(localized: "ChatView.Context.StoriesUsed"), action: {
                    if let questionId = contextMenuElem.elem.questionId {
                        let result = try await ApiModel.shared.findQuestionDetails(request: questionDetailsRequest(questionId: questionId))
                        HomeModel.shared.openStoriesUsedSheet(result)
                    }
                    
                }),
                ButtonContextMenuAction(label: String(localized: "ChatView.Context.Feedback"), action: {
                    if let questionId = contextMenuElem.elem.questionId {
                        HomeModel.shared.openFeedbackSheet(questionId)
                    }
                }),
                ShareContextmenuAction(content: contextMenuElem.elem.text ?? "")
            ]
        case .userTranscript:
            return [
                ButtonContextMenuAction(label: String(localized: "Ask again"), action: {
                    if let questionId = contextMenuElem.elem.questionId {
                        Task {
                            await model.reaskQuestion(questionId)
                        }
                        DispatchQueue.main.async {
                            model.sendScrollToBottomEvent()
                        }
                    }
                }),
                ButtonContextMenuAction(label: String(localized: "Copy"), action: {
                    if let text = contextMenuElem.elem.text {
                        UIPasteboard.general.string = text
                    }
                })
            ]
        case .storyList:
            return []
        }
    }
}


fileprivate struct SessionHeader: View {
    let session: Session
    @Binding var model: ChatViewModel
    
    var body: some View {
        HStack{
            VStack(alignment: .leading){
                Text(session.title ?? "Missing title")
                    .foregroundStyle(.textPrimary)
                    .font(Theme.condensedLight)
                    .lineLimit(1)
                Text("Created: \(session.createdTime!.formatted())")         .foregroundStyle(.textSecondary)
                    .font(Theme.condensedLightCaption)
            }
            Spacer()
            Button{
                model.showSessionHeaderContextMenu = true
            } label: {
                Image("Glyph=ThreeDots")
                    .padding(.vertical)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background{
            RoundedRectangle(cornerRadius: 20)
                .fill(.surfacePanel)
                .stroke(.borderPrimary)
                .opacity(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .overlay(alignment: .topTrailing){
            if model.showSessionHeaderContextMenu {
                ContextMenu(options: [
                    ButtonContextMenuAction(label: "Rename Session", action: {
                        model.showSessionRenameSheet = true
                    }),
                    ButtonContextMenuAction(label: "Delete", action: {
                        await model.deleteSession()
                    })
                ], dismiss: {
                })
                .padding(.trailing)
                .padding(.top, 40)
            }
        }
    }
}


struct ChatView_defaultPreview: View {
    @State private var buttonBounds: CGRect? = nil
    @State private var chatViewOpen = true
    
    var body: some View {
        GeometryReader{ geo in
            VStack(spacing: 0){
                Spacer()
                NavBar(activeTab: .constant(.network))
                    .onPreferenceChange(BoundsPreferenceKey.self, perform: { value in
                        if let value = value {
                            buttonBounds = geo[value]
                        }
                    })
            }
            .ignoresSafeArea(edges: .bottom)
            .overlay{
                if buttonBounds != nil && chatViewOpen {
                    ChatView(chatViewOpen: $chatViewOpen, buttonBounds: buttonBounds!, globalBounds: geo.frame(in: .named("home")))
                    
                }
            }
            .background(Background())
            
        }
        .coordinateSpace(name: "home")
    }
}

#Preview {
    ChatView_defaultPreview()
}
