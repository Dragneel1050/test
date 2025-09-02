//
//  StoryListView.swift
//  Corbo
//
//  Created by Agustín Nanni on 17/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct StoryListView: View {
    let maxStoriesToShow = 3
    let data: storyListResponseData
    
    @State private var allStories: [storyWithEntities]
    @State private var canShowMoreStories: Bool
    @State private var storiesToShow: [storyWithEntities]
    
    init(storyList: storyListResponseData) {
        self.data = storyList
        self._canShowMoreStories = State(initialValue: false)
        self._allStories = State(initialValue: data.storyList)
        self._storiesToShow = State(initialValue: data.storyList)
    }
    
    var body: some View {
        VStack(alignment: .leading){
            VStack{
                ForEach(storiesToShow, id: \.id) { elem in
                    Button{
                        HomeModel.shared.chatViewOpen = false
                        HomeModel.shared.homeNavPath.append(elem)
                    } label: {
                        StoryCard(storyWithEntities: elem)
                    }
                }
            }
            Button {
                HomeModel.shared.homeNavPath.append(data)
                HomeModel.shared.chatViewOpen = false
            } label: {
                Text("Show all \(data.storyList.count) stories")
                    .font(Theme.textStories)
                    .foregroundStyle(.textEntity)
                    .underline()
            }
        }.onAppear{
            if self.allStories.count > maxStoriesToShow {
                canShowMoreStories = true
                storiesToShow = Array(self.allStories.prefix(maxStoriesToShow))
            }
        }.onReceive(StoriesModel.shared.storiesPublisher, perform: { event in
            if event.type == .deleted {
                allStories = allStories.filter({ $0.id != event.id })
                storiesToShow = Array(self.allStories.prefix(maxStoriesToShow))
            }
        })
    }
}

#Preview {
    StoryListView(storyList: storyListResponseData(storyList: [storyWithEntities(story: Story(id: 1, content: "The quick brown fox jumps over the lazy dog", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "fox", type: .person, externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US"))
    ], prompt: "hello this is a test"))
}
