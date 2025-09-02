//

import SwiftUI
import AppIntents

struct Home: View {
    @State private var model = HomeModel.shared
    @State private var nav = NavigationModel.shared
    
    @State private var toast = ToastsModel.shared
    
    var body: some View {
        GeometryReader{ geo in
            NavigationStack(path: $model.homeNavPath){
                VStack(spacing: 0){
                    Group{
                        switch model.activeTab {
                            case .network:
                                Sessions()
                                .trackOnAppear{
                                    ViewNetwork()
                                }
                            case .stories:
                                Stories()
                                .trackOnAppear{
                                    ViewStories()
                                }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        SiriTipView(intent: CreateStoryIntent(), isVisible: $model.showSiriTip)
                            .siriTipViewStyle(.dark)
                            .padding()
                    }
                    NavBar(activeTab: $model.activeTab)
                        .onPreferenceChange(BoundsPreferenceKey.self, perform: { value in
                            if let value = value {
                                model.buttonBounds = geo[value]
                             }
                        })
                }
                .background(Background())
                .ignoresSafeArea(edges: .bottom)
                .navigationDestination(for: storyListResponseData.self, destination: { data in
                    StoryListResultView(storyList: data)
                })
                .navigationDestination(for: storyWithEntities.self, destination: { data in
                    StoryDetails(storyWithEntities: data, onBack: {
                        if HomeModel.shared.homeNavPath.count > 0 {
                            HomeModel.shared.homeNavPath.removeLast()
                        }
                    })
                })
                .navigationDestination(for: basicContactWithStoryCount.self, destination: { contact in
                    ContactDetails(contactId: contact.id)
                })
                .navigationDestination(isPresented: $model.showSettings, destination: {
                    Settings()
                })
            }
            .opacity(model.chatViewOpen ? 0.1 : 1)
            .blur(radius: model.chatViewOpen ? 3 : 0)
            .background(Background())
            .disabled(model.chatViewOpen)
            .overlay{
                if model.buttonBounds != nil && model.chatViewOpen {
                    ChatView(chatViewOpen: $model.chatViewOpen, buttonBounds: model.buttonBounds!, globalBounds: geo.frame(in: .named("home")))
                        .trackOnAppear {
                            ViewChatPopup()
                            ChatSessionStarted()
                        }
                }
            }
        }
        .coordinateSpace(name: homeSpaceCoordinateName)
        .sheet(isPresented: $model.showEntityTray, onDismiss: {
            NavigationModel.shared.closeEntityBinding()
        }) {
            if let context = nav.entityBindingContext {
                EntityTray(context: context)
            }
        }
        .sheet(isPresented: $model.feedbackViewOpen) {
            if let questionId = model.feedbackQuestionId {
                SubmitFeedbackView(questionId: questionId)
            }
        }
        .sheet(isPresented: $model.storiesUsedViewOpen) {
            Toasts(state: $toast.toastState){
                if let payload = model.storiesUsedViewPayload {
                    StoriesUsedView(storyList: payload)
                }
            }
        }
        .onChange(of: nav.entityBindingContext, { _, new in
            model.showEntityTray = new != nil
        })
        .onChange(of: model.chatViewOpen) { _, new in
            if !new {
                Task{
                    await NetworkViewModel.shared.findListSessionResponse()
                }
            }
        }
    }
}

let homeSpaceCoordinateName = "home"

#Preview {
    Home()
}
