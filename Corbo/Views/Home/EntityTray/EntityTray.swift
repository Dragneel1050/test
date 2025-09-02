//
//  EntityTray.swift
//  Corbo
//
//  Created by Agustín Nanni on 19/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct EntityTray: View {    
    init(context: entityBindingContext) {
        self.model = EntityTrayModel(context: context)
    }
    
    @State private var model: EntityTrayModel
    
    var body: some View {
        VStack{
            if model.working {
                loadingView(model: $model)
            } else {
                switch model.state {
                case .searchEntity:
                    ContactSearch(model: $model)
                case .createContact:
                    ContactCreation(model: $model)
                }
                Spacer()
            }
        }
        .padding()
        .presentationDetents(model.sheetPresentationDetents)
        .presentationBackground{Color.black}
    }
}

fileprivate struct loadingView: View {
    @Binding var model: EntityTrayModel
    
    var body: some View {
        VStack{
            ContactHeader(model: $model)
            VStack{
                Spacer()
                ProgressView()
                    .tint(.textPrimary)
                Spacer()
            }
        }
    }
}

fileprivate struct EntityTray_DefaultPreview: View {
    @State private var showSheet = false
    
    var body: some View {
        GeometryReader{ _ in
            HStack{
                Spacer()
                VStack{
                    Spacer()
                    Button{
                        showSheet.toggle()
                    } label: {
                        Text("EntityTray.ToggleSheet")
                    }
                    Spacer()
                }
                .sheet(isPresented: $showSheet) {
                    EntityTray(context: entityBindingContext(entity: wordEntity(name: "Pepe Argento"), storyId: 1, questionId: -1))
                }
                Spacer()
            }
        }
        .background{
            Background()
        }
    }
}

#Preview {
    EntityTray_DefaultPreview()
}
