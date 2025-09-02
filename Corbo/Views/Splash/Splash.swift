//
//  Splash.swift
//  Corbo
//
//  Created by admin on 25/09/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct Splash: View {
    
    
    @State private var auth = AuthModel.shared
    @State private var nav = NavigationModel.shared
    @State private var locationModel = LocationModel.shared
    @State private var googleSyncViewModel = GoogleSyncViewModel.shared
    
    var asyncTaskGroup = DispatchGroup()
    
    var body: some View {
        Group {
            switch nav.currentNav {
            case .splash:
                VStack {
                    Image("SplashLogo")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 85)
                        .padding(.top, 250)
                    Spacer()
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Background())
                .onChange(of: auth.working, { oldValue, newValue in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        handleAuthWorkingChange(oldValue: oldValue, newValue: newValue)
                    }
                })
            case .home:
                HomePermissionsWrapper()
            case .onboarding:
                Onboarding()
            }
        }
    }
    
    
    func handleAuthWorkingChange(oldValue: Bool, newValue: Bool) {
        if oldValue == true && newValue == false {
            if AuthModel.shared.isLoggedIn {
                doLogin()
            } else {
                NavigationModel.shared.navigate(.onboarding)
            }
        }
    }
    
    func doLogin() {
        Task{ @MainActor in
            NavigationModel.shared.navigate(.home)
        }
        Task{
            _ = try? await ContactsModel.shared.listContacts()
        }
    }
    
}

#Preview {
    Splash()
}
