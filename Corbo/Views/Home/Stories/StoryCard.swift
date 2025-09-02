//
//  StoryCard.swift
//  Corbo
//
//  Created by Agustín Nanni on 05/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct StoryCard: View {
    let storyWithEntities: storyWithEntities
    private let textWordLimit = 10
        
    var body: some View {
        Card(width: .content, height: .content){
            VStack(alignment: .leading, spacing: 10){
                VStack(alignment: .leading, spacing: 0){
                    StoryTools.buildCardText(content: content(), storyId: storyWithEntities.id, entityList: storyWithEntities.entityList)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                HStack{
                    Text("Created: \(StoryTools.createdText(dateCreated: storyWithEntities.story!.createdTime))")
                        .font(Theme.caption)
                        .foregroundStyle(.textPrimary)
                    Spacer()
                }
            }
        }
    }
    
    @MainActor
    func content() -> String {
        return storyWithEntities.story?.content ?? "missing content"
    }
}

#Preview {
    StoryCard(storyWithEntities: storyWithEntities(story: Story(id: 1, content: "My best friend John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "cool", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "pretty", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")))
        .background{
            Color.red
        }
}

#Preview{
    VStack{
        StoryCard(storyWithEntities: storyWithEntities(story: Story(id: 1, content: "My best friend John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool. My best friend is John Rambo he is pretty cool.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "cool", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "pretty", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")))
            .background{
                Color.red
            }
        StoryCard(storyWithEntities: storyWithEntities(story: Story(id: 57786, content: "Okay, that's at least new. Give me something that is good. I wasn't recording the story. Come on, don't be like that.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "cool", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "pretty", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")))
            .background{
                Color.red
            }
        StoryCard(storyWithEntities: storyWithEntities(story: Story(id: 1, content: "Today I went with my friends to a bar and we had a lot of fun.We also ate some pizza, and it was great.And there were video games in the bar, so they were awesome.", userAccountId: 1, createdTime: Date.now, lastModifiedTime: Date.now), entityList: [wordEntity(name: "John Rambo", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "cool", type: wordEntityType(rawValue: "person"), externalId: 1), wordEntity(name: "pretty", type: wordEntityType(rawValue: "person"), externalId: 1)], location: Location(lat: 1, lon: 2, geocode: "Hallandale Beach, FL, US")))
            .background{
                Color.red
            }
    }
}
