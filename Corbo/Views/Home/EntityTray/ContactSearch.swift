//
//  ContactSearch.swift
//  Corbo
//
//  Created by Agustín Nanni on 19/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI
import Combine

struct ContactSearch: View {
    @Binding var model: EntityTrayModel
    @State private var cancellables = Set<AnyCancellable>()
    
    init(model: Binding<EntityTrayModel>) {
        self._model = model
    }
    
    var body: some View {
        VStack{
            ContactHeader(model: $model)
            HStack{
                ZStack{
                    if model.searchText.isEmpty {
                        HStack{
                            Text("ContactSearch.Prompt")
                                .font(Theme.formPlaceholder)
                                .foregroundStyle(.textSecondary)
                            Spacer()
                        }
                    }
                    TextField("", text: $model.searchText)
                        .foregroundStyle(.textPrimary)
                }
                if !model.searchText.isEmpty {
                    Image("Glyph=XmarkSmall")
                        .foregroundStyle(.textPrimary)
                        .onTapGesture {
                            model.searchText = ""
                        }
                        .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: model.searchText)
                        .transition(.move(edge: .trailing))
                }
            }
            .padding()
            .background{
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.chatIconPrimary, lineWidth: 1.0)
            }
            contactResultList(contacts: model.contactResultList, model: $model)
        }
    }
}

fileprivate struct contactResultList: View {
    let contacts: [basicContactWithStoryCount]
    @Binding var model: EntityTrayModel
    
    private let adaptiveColumn = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false){
            LazyVGrid(columns: adaptiveColumn, alignment: .leading) {
                ForEach(contacts, id: \.contactId) { item in
                    contactPill(item)
                }
            }
        }
        .frame(height: 100)
    }
    
    @ViewBuilder
    func contactPill(_ contact: basicContactWithStoryCount) -> some View {
        Button{
            Task{
                await model.bindContact(contact)
            }
        } label: {
            Text(contact.contactName)
                .foregroundStyle(.textPrimary)
                .font(Theme.contactTrayPerson)
                .padding(8)
                .background{
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.chatIconPrimary, lineWidth: 1.0)
                }
        }
    }
}

#Preview {
    ContactSearch(model: 
            .constant(
                EntityTrayModel(
                    context:
                        entityBindingContext(entity:
                            wordEntity(name: "Pepe Argento"),
                             storyId: 1,
                             questionId: -1
                            )
                    )
        )
    )
    .background{
        Color.black
    }
}
