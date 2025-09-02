//
//  Forms.swift
//  Corbo
//
//  Created by Agustín Nanni on 19/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct FormLabel: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(Theme.formLabelTitle)
            .foregroundStyle(.textHeader)
    }
}

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var error: Bool
    @FocusState var focus: Bool
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    init(placeholder: String = "", text: Binding<String>, error: Binding<Bool>? = nil) {
        self.placeholder = placeholder
        self._text = text
        
        let errorBinding = {
            if let error = error {
                return error
            } else {
                return .constant(false)
            }
        }()
        
        self._error = errorBinding
        self.focus = focus
    }
    
    var body: some View {
        HStack{
            ZStack(alignment: .leading){
                Text(placeholder)
                    .font(Theme.formPlaceholder)
                    .foregroundStyle(.textSecondary)
                    .opacity(text.isEmpty ? 1 : 0)
                TextField("", text: $text)
                    .focused($focus)
                    .font(Theme.barlowRegular)
                    .foregroundStyle(.textPrimary)
                    .onChange(of: text, { _, _ in
                        error = false
                    })
            }
            if isEnabled {
                Button{
                    text = ""
                } label: {
                    Image("Glyph=XmarkSmall")
                        .foregroundStyle(.textPrimary)
                }
            }
        }
        .padding()
        .background{
            RoundedRectangle(cornerRadius: 8)
                .fill(.surfaceFormControl)
                .stroke(strokeColor())
        }
    }
    
    func strokeColor() -> Color {
        if error {
            return .red
        }
        
        if focus {
            return .borderFormFocus
        } else {
            return .borderForm
        }
    }
}

fileprivate struct FormsPreviews: View{
    @State private var text = ""
    @State private var text2 = ""
    
    var body: some View {
        GeometryReader { _ in
            VStack{
                FormLabel("Create a contact")
                FormTextField(placeholder: "Placeholder", text: $text)
                FormTextField(placeholder: "Placeholder 2", text: $text2)
            }.padding()
        }
        .background{
            Background()
        }
    }
}

#Preview {
    FormsPreviews()
}
