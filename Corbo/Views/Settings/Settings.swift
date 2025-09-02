//
//  Settings.swift
//  Corbo
//
//  Created by Agustín Nanni on 07/08/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI
import GoogleSignIn

struct Settings: View {
    @State private var home = HomeModel.shared
    @State private var working = false
    @State private var isLoggedInWithGoogle: Bool = false
    @State var email: String = ""
    @Environment(\.openURL) private var openUrl
    @EnvironmentObject private var delegate: AppDelegate
    
    @State private var gmailSyncInProgress = false
    @State private var calendarSyncInProgress = false
    
    @State private var googleSyncPresented : Bool = false
    @State private var emailSyncID : String?
    @State private var calendarSyncID : String?
    
    
    
    var body: some View {
        VStack{
            header()
            ScrollView{
                settingsTitle(text: "Configure Corbo")
                SettingsSection(working: $working){
                    DefaultModePicker()
                    AppDivider()
                        .overlay(Color.formDivider)
                    SettingsButton(text: "Sync Contacts", action: {
                        HomeModel.shared.enqueuePermissionRequest(.contacts)
                        HomeModel.shared.setNextEnqueuedPermission()
                    })
                }
                .padding([.horizontal, .bottom])
                
                
                //MARK: - GmailSync Section
                settingsTitle(text: "Gmail Sync")
                if let emailSyncID = emailSyncID {
                    Text(emailSyncID)
                        .foregroundStyle(.iconSecondary)
                        .font(Theme.barlowLight)
                        .frame(maxWidth: .infinity, alignment: .leading) // Aligns text to the left
                        .padding(.horizontal, 40)
                }
                
                SettingsSection(working: $working){
                    
                    if let emailSyncID = emailSyncID {
                        
                        Button {
                            gmailSyncInProgress = true
                            Task {
                                await signOut(email: emailSyncID, forType: .gmail)
                            }
                        } label: {
                            if gmailSyncInProgress {
                                ProgressView()
                                    .tint(Color.chatPrimary)
                            } else {
                                Text("Sign Out")
                                    .foregroundStyle(.textError)
                                    .frame(maxWidth: .infinity, alignment: .leading) // Aligns text to the left
                            }
                        }
                        
                    } else {
                        if gmailSyncInProgress {
                            ProgressView()
                                .tint(Color.chatPrimary)
                        } else {
                            SettingsButton(text: "Sign In to Google Account") {
                                gmailSyncInProgress = true
                                delegate.requestGoogleSigninAuth(scope: .gmail)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 25)
                
                
                //MARK: - CalendarSync Section
                settingsTitle(text: "Calendar Sync")
                if let calendarSyncID = calendarSyncID {
                    Text(calendarSyncID)
                        .foregroundStyle(.iconSecondary)
                        .font(Theme.barlowLight)
                        .frame(maxWidth: .infinity, alignment: .leading) // Aligns text to the left
                        .padding(.horizontal, 40)
                }
                
                SettingsSection(working: $working){
                    
                    if let calendarSyncID = calendarSyncID {
                        
                        Button {
                            calendarSyncInProgress = true
                            Task {
                                await signOut(email: calendarSyncID, forType: .calendar)
                            }
                        } label: {
                            if calendarSyncInProgress {
                                ProgressView()
                                    .tint(Color.chatPrimary)
                            } else {
                                Text("Sign Out")
                                    .foregroundStyle(.textError)
                                    .frame(maxWidth: .infinity, alignment: .leading) // Aligns text to the left
                            }
                        }
                        
                    } else {
                        if calendarSyncInProgress {
                            ProgressView()
                                .tint(Color.chatPrimary)
                        } else {
                            SettingsButton(text: "Sign In to Google Account") {
                                calendarSyncInProgress = true
                                delegate.requestGoogleSigninAuth(scope: .calendar)
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
                
                
                //MARK: - Account Section
                settingsTitle(text: "Account")
                
                SettingsSection(working: $working){
                    
                    SettingsButton(text: "Support", action: {
                        openUrl(URL(string: "http://corbo.ai/support")!)
                    })
                    
                    AppDivider()
                        .overlay(Color.formDivider)
                    
                    Button(action: {
                        AuthModel.shared.logout()
                        home.showSettings = false
                    }, label: {
                        HStack{
                            Text("Sign out")
                                .font(Theme.settingButton)
                                .foregroundStyle(Color.textError)
                            Spacer()
                        }
                    })
                    
                }
                .padding([.horizontal, .bottom])
                
            }
            
            NavBar(activeTab: $home.activeTab, onTap: {
                home.showSettings = false
            })
        }
        .ignoresSafeArea(edges: .bottom)
        .background{
            Background()
        }
        .toolbar(.hidden)
        .onReceive(delegate.googleSigninStatesProducer, perform: { value in
            switch value {
            case .working:
                break
            case .failed, .done:
                gmailSyncInProgress = false
                calendarSyncInProgress = false
                checkForOfflineSync()
            }
        })
        .onAppear() {
            checkForOnlineSync()
        }
    }
    
    func checkForOnlineSync() {
        
        working = true
        
        Task {
            do {
                
                let result1 = try await ApiModel.shared.prepareSettings()
                if !result1.calendarSync.isEmpty {
                    ConfigModel.shared.updateExternalSync(calendarSyncID: result1.calendarSync.first?.email)
                }
                
                let result = try await ApiModel.shared.getEmailSyncStatus()
                if result.emailSync.error == false, let enabled = result.emailSync.enabled, enabled == true {
                    ConfigModel.shared.updateExternalSync(emailSyncID: result.emailSync.email)
                }
                
            } catch let err {
                if case ApiErrors.RequestTimeout = err {
                    // Handle the timeout error
                    DispatchQueue.main.async {
                        ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                    }
                } else {
                    AppLogs.defaultLogger.error("initializeAuth: \(err)")
                    DispatchQueue.main.async {
                        ToastsModel.shared.notifyError(message: "Unable to get sync status.")
                    }
                }
            }
            working = false
        }
        
        checkForOfflineSync()
        
    }
    
    func checkForOfflineSync() {
        
        let syncDetail = ConfigModel.shared.getExternalSync()
        
        if let emailID = syncDetail?.emailSyncID {
            self.emailSyncID = emailID
        }
        
        if let calendarID = syncDetail?.calendarSyncID {
            self.calendarSyncID = calendarID
        }
    }
    
    func signOut(email: String, forType : GoogleSyncTypes) async {
        switch forType {
        case .gmail:
            let result = await GoogleSyncViewModel.shared.disableGmailSync(email: email)
            if result?.emailSync.error == false, let enabled = result?.emailSync.enabled, enabled == false {
                ConfigModel.shared.updateExternalSync(emailSyncID: "")
                emailSyncID = nil
//                ToastsModel.shared.displayMessage(text: "Gmail Sync Disabled")
            } else {
                ToastsModel.shared.notifyError(message: "Can't be disconnected. Please check internet connection.")
            }
            gmailSyncInProgress = false
        case .calendar:
            let result = await GoogleSyncViewModel.shared.disableCalendarSync(email: email)
            if result {
                ConfigModel.shared.updateExternalSync(calendarSyncID: "")
                calendarSyncID = nil
//                ToastsModel.shared.displayMessage(text: "Calendar Sync Disabled")
            } else {
                ToastsModel.shared.notifyError(message: "Can't be disconnected. Please check internet connection.")
            }
            calendarSyncInProgress = false
        }
        
    }
    
    
    @ViewBuilder
    func header() -> some View {
        ZStack{
            HStack{
                Button {
                    home.showSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundStyle(.textTitle)
                }
                Spacer()
            }
            HStack{
                Spacer()
                Text("SETTINGS")
                    .foregroundStyle(.textTitle)
                    .font(Theme.textTitle)
                Spacer()
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func settingsTitle(text: String) -> some View {
        HStack{
            Text(text)
                .foregroundStyle(Color.chatPrimary)
                .font(Theme.title)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

fileprivate struct DefaultModePicker: View {
    @AppStorage(ConfigModel.inputModeKey, store: ConfigModel.userDefaults()) private var inputMode = InputModes.Voice.rawValue
    
    var body: some View {
        HStack{
            Text("Default chat mode")
                .font(Theme.settingButton)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            HStack{
                ForEach(InputModes.allCases, id: \.self) { mode in
                    let rawValue = mode.rawValue
                    Button {
                        inputMode = rawValue
                    } label: {
                        if inputMode == rawValue {
                            Text(rawValue)
                                .font(Theme.formLabelSubtitle)
                                .foregroundStyle(.chatTextBot)
                                .padding(5)
                                .background{
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.chatPrimary)
                                }
                        } else {
                            Text(rawValue)
                                .font(Theme.formLabelSubtitle)
                                .foregroundStyle(.textPrimary)
                                .padding(5)
                                .background{
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.surfaceSecondary)
                                }
                        }
                    }
                }
            }
        }
    }
}

fileprivate struct SettingsButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            HStack{
                Text(text)
                    .font(Theme.settingButton)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image("Glyph=ChevronRight")
                    .foregroundStyle(Color.textPrimary)
            }
        })
    }
}

fileprivate struct SettingsSection<Content: View> : View {
    @Binding var working: Bool
    @ViewBuilder var content: Content
    
    @State private var loading = false
    
    var body: some View {
        VStack{
            content
                .opacity(working ? 0 : 1)
        }
        .padding()
        .background{
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.surfaceFormControl)
                .opacity(loading ? 0.6 : 1 )
        }
        .onAppear{
            withAnimation(.easeInOut.repeatForever(autoreverses: true)){
                loading = true
            }
        }
        .onChange(of: working, { _, new in
            self.loading = new
        })
    }
}

#Preview {
    Settings(email: "")
}
