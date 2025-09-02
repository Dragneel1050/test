//
//  ContactCreation.swift
//  Corbo
//
//  Created by Agustín Nanni on 19/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct ContactCreation: View {
    @Binding var model: EntityTrayModel
    @State private var first = ""
    @State private var last = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var alias = ""
    @State private var firstErr = false
    @State private var lastErr = false
    
    var body: some View {
        ScrollView{
            VStack{
                ContactHeader(model: $model)
                HStack{
                    Text("Create new contact")
                        .font(Theme.formLabelTitle)
                        .foregroundStyle(.textHeader)
                    Spacer()
                }
                .padding(.top)

                FormTextField(placeholder: String(localized: "ContactCreation.Placeholder0"), text: $first, error: $firstErr)
                FormTextField(placeholder: String(localized: "ContactCreation.Placeholder1"), text: $last, error: $lastErr)
                FormTextField(placeholder: String(localized: "ContactCreation.Placeholder2"), text: $email)
                FormTextField(placeholder: String(localized: "ContactCreation.Placeholder3"), text: $phone)
                FormTextField(placeholder: String(localized: "ContactCreation.Placeholder4"), text: $alias)
                
                FormButton(action: {
                    if first.isEmpty {
                        firstErr = true
                    }
                    if last.isEmpty {
                        lastErr = true
                    }
                    
                    if firstErr || lastErr {
                        return
                    }
                    
                    await model.createAndBindContact(createContactRequest(firstName: first, lastName: last, email: email, phone: phone, alias: alias))
                }, label: String(localized: "ContactSearch.SaveContact"))
                    .padding(.top, 30)
            }.padding()
        }
    }
}

#Preview {
    ContactCreation(model: .constant(EntityTrayModel(
        context:
            entityBindingContext(entity:
                wordEntity(name: "Pepe Argento"),
                 storyId: 1,
                 questionId: -1
                )
        )))
        .background{
            Color.black
        }
}
