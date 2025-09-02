//
//  RenameSessionTray.swift
//  Corbo
//
//  Created by Agustín Nanni on 30/08/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct RenameSessionTray: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var nameErr = false
    @Binding var model: ChatViewModel
    let sessionId: Int64
    
    init(name: String = "",  sessionId: Int64, model: Binding<ChatViewModel>) {
        self._name = State(initialValue: name)
        self.sessionId = sessionId
        self._model = model
    }
    
    var body: some View {
        VStack(spacing: 25){
            HStack{
                Text("Rename Session")
                    .font(Theme.formLabelTitle)
                    .foregroundStyle(.textHeader)
                Spacer()
                Button{
                    dismiss()
                } label: {
                    Image("Glyph=XmarkSmall")
                        .foregroundColor(.textPrimary)
                }
            }
            .padding(.top)
            
            FormTextField(placeholder: "Session Name", text: $name, error: $nameErr)
            
            FormButton(action: {
                if name.isEmpty {
                    nameErr = true
                }
                
                if nameErr {
                    return
                }
                
                do {
                    try await ApiModel.shared.renameSession(sessionId: sessionId, title: name)
                    model.session?.title = name
                    dismiss()
                } catch let err {
                    
                    if case ApiErrors.RequestTimeout = err {
                        // Handle the timeout error
                        ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                    } else {
                        ToastsModel.shared.notifyError(context: "ApiModel.shared.renameSession()", error: err)
                    }
                }
            }, label: "Save")
        }
        .padding(.horizontal)
        .padding(.top, 5)
    }
}

#Preview {
    RenameSessionTray(name: "Test", sessionId: 1, model: .constant(ChatViewModel(chatViewOpen: .constant(true))))
}
