//
//  AuthWrapper.swift
//  ShareToCorbo
//
//  Created by Agustín Nanni on 29/05/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct ExtensionAuthView<Content: View>: View {
    @State private var loading = true
    @State private var disabled = false
    
    let content: Content
    var authController = AuthModel.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack{
            if authController.working {
                OnboardingTopNav()
                AppProgressView()
                
            } else {
                if authController.isLoggedIn {
                    VStack(spacing: 15){
                        OnboardingTopNav()
                        content
                    }
                } else {
                    OnboardingTopNav()
                    Spacer()
                    Text("Please log into the APP in order to start sharing content with Corbo")
                        .font(Theme.regular)
                        .foregroundStyle(.textTitle)
                        .frame(width: 250)
                    Spacer()
                }
            }
        }
        .background{
            Background()
        }
    }
}
