//
//  StoriesUsedView.swift
//  Corbo
//
//  Created by Agustín Nanni on 18/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

enum StoriesUsedFlowNavigationStack: Hashable {
    case StoryDetail(story: storyWithEntities)
    case EditStory(story: storyWithEntities)
}

struct StoriesUsedView: View {
    let list: [storyWithSimilarity]
    
    init(storyList: questionDetailsResponse) {
        self.list = storyList.question?.context?.similarityList ?? []
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack{
                
                HStack{
                    
                    Button{
                    } label: {
                    }
                    
                    Spacer()
                    Text("\(list.count) \(storyText()) Used")
                        .font(Theme.title)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button{
                        HomeModel.shared.storiesUsedViewOpen = false
                    } label: {
                        Image("Glyph=XmarkSmall")
                            .foregroundStyle(.textPrimary)
                    }
                    
                }
                .padding(EdgeInsets(top: 16, leading: 20, bottom: 10, trailing: 20))
                
                ZStack {
                    Text("These are snapshots at the time the question was asked.")
                        .font(Theme.caption)
                        .foregroundStyle(Color.textHeader)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
                
                ScrollView{
                    VStack{
                        if list.isEmpty {
                            Spacer()
                        } else {
                            ForEach(list, id: \.id) { item in
                                let story = storyWithEntitiesFromStoryWithSimilarity(item)
                                Button {
                                    path.append(StoriesUsedFlowNavigationStack.StoryDetail(story: story))
                                } label: {
                                    StoryCard(storyWithEntities: story)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .background{
                Background()
            }
            .toolbar(.hidden)
            .navigationDestination(for: StoriesUsedFlowNavigationStack.self) { stack in
                switch stack {
                case .StoryDetail(let story):
                    StoriesUsedDetail(storyWithEntities: story, path: $path)
                        .toolbar(.hidden)
                case .EditStory(let story):
                    StoryDetails(storyWithEntities: story, onBack: {
                        path.removeLast()
                    })
                }
            }
        }
    }
    
    func storyText() -> String {
        if list.count == 1 {
            return "Story"
        } else {
            return "Stories"
        }
    }
    
    func storyWithEntitiesFromStoryWithSimilarity(_ src: storyWithSimilarity) -> storyWithEntities {
        return storyWithEntities(story: Story(id: src.id ?? -1, content: src.content ?? "", userAccountId: src.userAccountId ?? -1, createdTime: src.createdTime ?? Date.now, lastModifiedTime: src.lastModifiedTime ?? Date.now), entityList: nil, location: Location(lat: 1, lon: 2, geocode: "Hallandale, FL, US"))
    }
}

fileprivate struct StoriesUsedDetail: View {
    
    let storyWithEntities: storyWithEntities
    
    @Binding var path: NavigationPath
    
    @State private var storyText = ""
    @State private var editorText = ""
    @FocusState private var focus
    @State private var editMode = false
    @State private var requestInProgress : Bool = false
    
    @State private var showSessionHeaderContextMenu = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            VStack{
                
                HStack{
                    Button{
                        dismiss()
                    } label: {
                        Image("Glyph=ChevronLeft")
                            .foregroundStyle(.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .center) {
                        Text("Story Used")
                            .font(Theme.title)
                            .foregroundStyle(.textPrimary)
                        
                    }
                    Spacer()
                    Button{
                        HomeModel.shared.storiesUsedViewOpen = false
                    } label: {
                        Image("Glyph=XmarkSmall")
                            .foregroundStyle(.textPrimary)
                    }
                }
                .padding(EdgeInsets(top: 16, leading: 10, bottom: 10, trailing: 10))
                
                ZStack {
                    Text("These are snapshots at the time the question was asked.")
                        .font(Theme.caption)
                        .foregroundStyle(Color.textHeader)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
                
                Card(width: .content, height: .content){
                    ScrollView(showsIndicators: false){
                        VStack(alignment: .leading){
                            HStack{
                                Text("Created: \(StoryTools.createdText(dateCreated: storyWithEntities.story!.createdTime))")
                                    .font(Theme.caption)
                                    .foregroundStyle(.iconSecondary)
                                Spacer()
                                Button{
                                    // Uncomment this if you want to show the context menu
//                                    self.showSessionHeaderContextMenu = true
                                    Task {
                                        do {
                                            let story = try await ApiModel.shared.getUpdatedStroy(id: storyWithEntities.story!.id)
                                            path.append(StoriesUsedFlowNavigationStack.EditStory(story: story))
                                        }  catch {
                                            ToastsModel.shared.notifyError(message: "Story no longer exists")
                                        }
                                    }
                                } label: {
                                    // Three Dots for Context menu
                                    /*
                                     Image("Glyph=ThreeDots")
                                        .padding(.vertical)
                                     */
                                    
                                    Text("Open Story >")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.textHeader)
                                        
                                }
                                .padding(.bottom, 8)
                            }
                            
                            if self.editMode {
                                TextField("", text: $editorText, axis: .vertical)
                                    .font(Theme.textStories)
                                    .foregroundStyle(.textPrimary)
                                    .focused($focus)
                                    .offset(y: -1)
                            } else {
                                StoryTools.buildCardText(content: storyText, storyId: storyWithEntities.id, entityList: storyWithEntities.entityList)
                                // Editing on the same page related Gesture
                                /*
                                    .onTapGesture {
                                        if !requestInProgress {
                                            isEditing(true)
                                        }
                                    }
                                 */
                            }
                        }
                        /*
                         .confirmationDialog("Open location in", isPresented: $showingMapConfirmation, actions:
                         {
                         if let mapsUrl = self.createAppleMapsUrl() {
                         Button("Maps") {
                         openURL(mapsUrl)
                         showingMapConfirmation = false
                         }
                         }
                         if let googleMapsUrl = self.createGoogleMapsUrl() {
                         Button("Google Maps") {
                         openURL(googleMapsUrl)
                         showingMapConfirmation = false
                         }
                         }
                         Button("Cancel", role: .cancel) {
                         showingMapConfirmation = false
                         }
                         })
                         */
                        
                    }
//                    .border(Color.white, width: 1)
                    .padding(10)
                    
                    // If you want to edit this on the current screen, please uncomment this
                    /*
                    if editMode {
                        HStack{
                            Button {
                                self.editorText = storyText
                                isEditing(false)
                            } label: {
                                Image("Glyph=ChatXMark")
                                    .foregroundStyle(.chatPrimary)
                            }
                            Spacer()
                            Button {
                                if !requestInProgress {
                                    self.requestInProgress = true
                                    applyEdit()
                                }
                            } label: {
                                Image("Glyph=ChatCheckmark")
                                    .foregroundStyle(.chatPrimary)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                     */
                    
                }
                
            }
            
            if requestInProgress {
                ProgressView()
                    .tint(.chatPrimary)
            }
            
        }
        .padding([.horizontal, .bottom])
        .background{
            Background()
        }
        
        // This is the context menu which will be shown on Edit Story button. Uncomment this if you show the menu
        
        /*
        .overlay(alignment: .topTrailing){
            if self.showSessionHeaderContextMenu {
                ContextMenu(options: [
                    ButtonContextMenuAction(label: "Edit", action: {
                        if !requestInProgress {
                            isEditing(true)
                            self.showSessionHeaderContextMenu = false
                        }
                    })
                ], dismiss: {
                })
                .padding(.trailing, 40)
                .padding(.top, 120)
            }
        }
        .onTapGesture {
            if self.showSessionHeaderContextMenu {
                self.showSessionHeaderContextMenu = false
            }
        }
         */
        
        // Lifecycle of the app
        .onAppear() {
            let storyContent = storyWithEntities.story?.content ?? ""
            self.editorText = storyContent
            self.storyText = storyContent
        }
    }
    
    // Editing on the same page related function
    /*
    func isEditing(_ value: Bool) {
        self.editMode = value
        self.focus = value
    }
    
    func applyEdit() {
        isEditing(false)
        Task{
            do {
                let result = try await StoriesModel.shared.editStory(id: storyWithEntities.id, content: editorText)
                self.editorText = result.story?.content ?? ""
                self.storyText = result.story?.content ?? ""
                
            } catch let err {
                await ToastsModel.shared.notifyError(context: "StoryDetails.handleEdit", error: err)
            }
            requestInProgress = false
        }
    }
     */
    
    
}
