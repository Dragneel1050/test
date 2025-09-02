//
//  StoryDetails.swift
//  Corbo
//
//  Created by Agustín Nanni on 06/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct StoryDetails: View {
    let storyWithEntities: storyWithEntities
    let onBack: () -> Void
    @State private var editMode = false
    @State private var editorText = ""
    @State private var storyText = ""
    @State private var showLosingConfirmation = false
    @State private var working = false
    @State private var showDeleteConfirmation = false
    @State private var showContextMenu = false
    @FocusState private var focus
    @State private var showingMapConfirmation = false
    @State private var keyboardPadding = CGFloat(0)
    @Environment(\.openURL) var openURL
    
    @State private var home = HomeModel.shared
    
    init(storyWithEntities: storyWithEntities, onBack: @escaping () -> Void) {
        self.storyWithEntities = storyWithEntities
        self.onBack = onBack
        self._storyText = State.init(initialValue: storyWithEntities.story?.content ?? "")
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            VStack{
                header()
                VStack{
                    Card(width: .content, height: .content){
                        
                        ScrollView(showsIndicators: false){
                            VStack(alignment: .leading){
                                if self.editMode {
                                    TextField("", text: $editorText, axis: .vertical)
                                        .font(Theme.textStories)
                                        .foregroundStyle(.textPrimary)
                                        .focused($focus)
                                } else {
                                    StoryTools.buildCardText(content: storyText, storyId: storyWithEntities.id, entityList: storyWithEntities.entityList)
                                }
                                Color.clear
                                    .frame(height: 0) // Takes no visible space
                                    .id("bottom") // Assign the ID to scroll
                            }
                            .confirmationDialog("You will lose your changes if you leave now!", isPresented: $showLosingConfirmation, titleVisibility: .visible, actions: {
                                Button("Leave", role: .destructive) {
                                    editMode = false
                                }
                                Button("Cancel", role: .cancel) {
                                    showLosingConfirmation = false
                                }
                            })
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
                            
                        }
                        .onTapGesture {
                            if !editMode {
                                handleCardTap()
                            } else {
                                focus.toggle()
                            }
                        }
                    }
                    .padding(.bottom, keyboardPadding)
                    HStack{
                        Text("Created: \(StoryTools.createdText(dateCreated: storyWithEntities.story!.createdTime))")
                            .font(Theme.caption)
                            .foregroundStyle(.iconSecondary)
                        Spacer()
                        if let location = storyWithEntities.location {
                            Button{
                                showingMapConfirmation = true
                            } label: {
                                HStack(spacing: 2){
                                    Spacer()
                                    Image("Glyph=Location")
                                        .foregroundStyle(.iconSecondary)
                                    Text(location.geocode ?? "")
                                        .font(Theme.caption)
                                        .foregroundStyle(.iconSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding([.horizontal, .bottom])
                NavBar(activeTab: $home.activeTab)
            }
            
            .ignoresSafeArea(edges: .bottom)
            .background{
                Background()
            }
            .toolbar(.hidden)
            .overlay(alignment: .topTrailing){
                if showContextMenu {
                    ContextMenu(options: [
                        ButtonContextMenuAction(label: "Delete story", action: {
                            showDeleteConfirmation = true
                        }),
                        ShareContextmenuAction(content: storyWithEntities.story?.content ?? "missing text")
                    ], dismiss: {})
                    .padding()
                }
            }
            .onTapGesture {
                if showContextMenu {
                    showContextMenu = false
                    return
                }
            }
            .confirmationDialog("This story will be permanently deleted!", isPresented: $showDeleteConfirmation, titleVisibility: .visible, actions: {
                Button("Delete", role: .destructive) {
                    handleDelete()
                    onBack()
                }
                Button("Cancel", role: .cancel) {
                    showDeleteConfirmation = false
                }
            })
            .onReceive(ContextualActionModel.shared.keyboardHeightPublisher, perform: { value in
                withAnimation(.easeInOut.speed(5)) {
                    let padding = value * 0.7
                    self.keyboardPadding = padding
                } completion: {
                    scrollProxy.scrollTo("bottom", anchor: .bottom)
                }
                
            })
            
        }
    }
    
    func handleCardTap() {
        if showContextMenu {
            showContextMenu = false
            return
        }
        
        if editMode {
            if editorText != storyText {
                showLosingConfirmation = true
            } else {
                editorText = storyText
                editMode = false
            }
        } else {
            focus = true
            editorText = storyText
            editMode = true
        }
    }
    
    @ViewBuilder
    func header() -> some View {
        if editMode {
            ZStack{
                HStack{
                    Button {
                        handleCardTap()
                    } label: {
                        Image("Glyph=XmarkSmall")
                            .foregroundStyle(working ? .iconDisabled : .textTitle )
                    }
                    Spacer()
                    Button {
                        handleEdit()
                    } label: {
                        Image("Glyph=Checkmark")
                            .foregroundStyle(.textTitle)
                            .foregroundStyle(working ? .iconDisabled : .textTitle )
                    }
                }
                HStack{
                    Spacer()
                    Text("STORY")
                        .foregroundStyle(.textTitle)
                        .font(Theme.textTitle)
                    Spacer()
                }
            }
            .padding()
        } else {
            ZStack{
                HStack{
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundStyle(.textTitle)
                    }
                    Spacer()
                }
                HStack{
                    Spacer()
                    Text("STORY")
                        .foregroundStyle(.textTitle)
                        .font(Theme.textTitle)
                    Spacer()
                }
                HStack{
                    Spacer()
                    Button{
                        showContextMenu = true
                    } label: {
                        Image("Glyph=ThreeDots")
                            .foregroundStyle(.textTitle)
                            .padding()
                    }
                }
            }
            .padding()
        }
    }
    
    func createGoogleMapsUrl() -> URL? {
        guard let location = storyWithEntities.location else {
            AppLogs.defaultLogger.warning("Location missing from story \(storyWithEntities.id)")
            return nil
        }
        var string = "https://www.google.com/maps/search/?api=1&query=\(location.lat),\(location.lon)"
        if let userFriendlyName = location.geocode?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            string += "&q=\(userFriendlyName)"
        }
        return URL(string: string)
    }
    
    func createAppleMapsUrl() -> URL? {
        guard let location = storyWithEntities.location else {
            AppLogs.defaultLogger.warning("Location missing from story \(storyWithEntities.id)")
            return nil
        }
        var string = "http://maps.apple.com/?&sll=\(location.lat),\(location.lon)"
        if let userFriendlyName = location.geocode?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            string += "&q=\(userFriendlyName)"
        }
        return URL(string: string)
    }
    
    func handleEdit() {
        self.working = true
        Task{
            do {
                try await StoriesModel.shared.editStory(id: storyWithEntities.id, content: editorText)
            } catch let err {
                
                if case ApiErrors.RequestTimeout = err {
                    // Handle the timeout error
                    ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                } else {
                    await ToastsModel.shared.notifyError(context: "StoryDetails.handleEdit", error: err)
                }
            }
            self.working = false
            self.focus = false
            self.editMode = false
            self.storyText = editorText
        }
    }
    
    func handleDelete() {
        self.working = true
        Task{
            do {
                try await StoriesModel.shared.deleteStory(id: storyWithEntities.id)
            } catch let err {
                if case ApiErrors.RequestTimeout = err {
                    // Handle the timeout error
                    ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                } else {
                    AppLogs.defaultLogger.error("handleDelete: \(err)")
                    await ToastsModel.shared.notifyError(context: "StoryDetails.handleDelete", error: err)
                }
            }
            self.working = false
            onBack()
        }
        
    }
}

#Preview {
    StoryDetails(storyWithEntities: storyWithEntities(story: Story(id: 1, content: "My best friend is John Rambo he is pretty cool.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "cool", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "pretty", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")), onBack: {print("back")})
}
