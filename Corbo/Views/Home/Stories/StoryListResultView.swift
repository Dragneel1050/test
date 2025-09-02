//
//  StoryListResultView.swift
//  Corbo
//
//  Created by Agustín Nanni on 05/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct StoryListResultView: View {
    let storyList: storyListResponseData
    
    @State private var list: [storyWithEntities]
    
    init(storyList: storyListResponseData) {
        self.storyList = storyList
        self._list = State.init(initialValue: storyList.storyList)
    }
    
    var body: some View {
        VStack{
            TopNav(variant: .stories, leftAction: {
                HomeModel.shared.homeNavPath.removeLast()
            }, rightAction: {
                HomeModel.shared.homeNavPath.removeLast()
            })
                .padding(.horizontal)
            HStack(alignment: .top){
                VStack(alignment: .leading) {
                    Text("\(storyList.storyList.count) \(storyText())")
                        .font(Theme.textStories)
                        .foregroundStyle(.textPrimary)
                    +
                    Text(" matching your query:")
                        .font(Theme.textStories)
                        .foregroundStyle(Color.textHeader)
                    
                    Text("\"\(storyList.prompt)\"")
                        .font(Theme.questionsSelectionSelected)
                        .foregroundStyle(Color.textHeader)
                    HStack{Spacer()}
                }
                Button{
                    HomeModel.shared.homeNavPath.removeLast()
                } label: {
                    Image("Glyph=Xmark")
                        .foregroundStyle(.textPrimary)
                }
            }
            .padding(.horizontal)
            if list.isEmpty {
                Spacer()
            } else {
                ScrollView{
                    VStack{
                        ForEach(list, id: \.id) { item in
                            Button {
                                HomeModel.shared.homeNavPath.append(item)
                            } label: {
                                StoryCard(storyWithEntities: item)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            NavBar(activeTab: .constant(.stories))
        }
        .ignoresSafeArea(edges: .bottom)
        .background{
            Background()
        }
        .toolbar(.hidden)
        .onReceive(StoriesModel.shared.storiesPublisher, perform: { event in
            if event.type == .deleted {
                list = list.filter({ $0.id != event.id })
            }
        })
    }
    
    func storyText() -> String {
        if storyList.storyList.count == 1 {
            return "Story"
        } else {
            return "Stories"
        }
    }
}

#Preview {
    StoryListResultView(storyList: storyListResponseData(storyList: [storyWithEntities(story: Story(id: 1, content: "My best friend is John Rambo he is pretty cool.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")), storyWithEntities(story: Story(id: 2, content: "My best dasda is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US"))], prompt: ""))
}
