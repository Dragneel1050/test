//
//  ContactHeader.swift
//  Corbo
//
//  Created by Agustín Nanni on 19/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct ContactHeader: View{
    @Binding var model: EntityTrayModel
    
    var body: some View {
        HStack{
            VStack(alignment: .leading){
                Text(model.context.entity.name ?? "Missing name")
                    .font(Theme.contactTrayTitle)
                    .foregroundStyle(.textEntity)
                Text("\(model.contactResultList.count) contacts found")
                    .font(Theme.contactTraySubtitle)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            if !model.working {
                HStack{
                    /*
                        ZStack{
                            Circle()
                                .stroke(.borderButton, lineWidth: 1.0)
                                .frame(height: 40)
                            Image("Glyph=Edit")
                        }
                    */
                    
                    switch model.state {
                    case .searchEntity:
                        createContactButton()
                    case .createContact:
                        returnButton()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func createContactButton() -> some View {
        Button{
            Task{ @MainActor in
                model.setState(.createContact)
            }
        } label: {
            ZStack{
                Circle()
                    .stroke(.chatIconPrimary, lineWidth: 1.0)
                    .frame(height: 40)
                Image("Glyph=Plus")
                    .foregroundStyle(.iconPrimary)
            }
        }
    }
    
    @ViewBuilder
    func returnButton() -> some View {
        Button{
            Task{ @MainActor in
                model.setState(.searchEntity)
            }
        } label: {
            Image("Glyph=XmarkSmall")
                .resizable()
                .scaledToFill()
                .foregroundStyle(.iconPrimary)
                .frame(width: 15, height: 15)
        }
        .padding(.trailing, 15)
    }
}

#Preview {
    ContactHeader(model: .constant(EntityTrayModel(
        context:
            entityBindingContext(entity:
                wordEntity(name: "Pepe Argento"),
                 storyId: 1,
                 questionId: -1
                )
        )))
        .padding()
        .background{
            Color.black
        }
}
