//
//  GoogleSyncView.swift
//  Corbo
//
//  Created by admin on 01/10/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI
import GoogleSignIn

struct GoogleSyncView: View {
    
    
    @State private var inProgress = false
    @State private var gmailSyncInProgress = true
    @State private var calendarSyncInProgress = true
    
    @State private var gmailSync: Bool = true
    @State private var calendarSync: Bool = true
    @State private var sharedCalendarSync: Bool = false
    @State private var contactsSync: Bool = true
    
    @Binding var email: String
    @Binding var isPresented: Bool // Binding to control dismissal
    
    
    var body: some View {
        
        VStack {
            
            header()
            pageTitle(text: "Sync to Corbo")
                .padding(.top, 40)
            
            
            VStack {
                
//                SyncOptionsView(iconName: "Gmail", title: "Gmail", desc: "Import your Email", valueToBindWithToggle: $gmailSync, waitForResponse: $gmailSyncInProgress, bottomDevider: true)
//                
//                SyncOptionsView(iconName: "GoogleCalendar", title: "Calendar", desc: "Import your Calendars", valueToBindWithToggle: $calendarSync, waitForResponse: $calendarSyncInProgress, bottomDevider: false)
                
                
                // To be implemented in next release
//                HStack {
//                    Spacer()
//                        .frame(width: 36, height: 36)
//                        .padding(.leading)
//                        .padding(.trailing, 10)
//                    HStack {
//                        Text("Include shared Calendars")
//                            .font(Theme.formLabelSubtitle)
//                            .foregroundColor(.textSecondary)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .layoutPriority(1)
//                        
//                        Toggle("", isOn: $sharedCalendarSync)
//                            .padding()
//                            .layoutPriority(0)
//                    }
//                }
//                
//                AppDivider(color: .borderForm)
//                    .padding(.leading, 16)
//                
//                SyncOptionsView(iconName: "Contacts", title: "Contacts", desc: "Import your Google Contacts", valueToBindWithToggle: $contactsSync, bottomDevider: false)
                
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.chatTextBot)
            )
            .padding(20)
            
            Button {
                Task {
                    await signOut()
                }
            } label: {
                if inProgress || gmailSyncInProgress || calendarSyncInProgress {
                    ProgressView()
                        .tint(Color.chatPrimary)
                } else {
                    Text("Sign Out of this account")
                        .foregroundStyle(.textError)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.chatTextBot)
            )
            .padding(20)
            
            Spacer()
        }
        .background(Background())
        .onAppear() {
            Task {
                await checkForGmailSync()
                await checkForCalendarSync()
            }
        }
        .onChange(of: gmailSync) { _ , newValue in
            gmailSyncInProgress = true
            Task {
                await newValue ? enableGmailSync() : disableGmailSync()
                gmailSyncInProgress = false
            }
        }
//        .onChange(of: calendarSync) { _ , newValue in
//            calendarSyncInProgress = true
//            Task {
//                await newValue ? enableGmailSync() : disableGmailSync()
//                gmailSyncInProgress = false
//            }
//        }
        
    }
    
    
    //MARK: - Gmail Sync Methods
    
    func checkForGmailSync() async {
//        let result = await GoogleSyncModel.shared.checkForGmailSync(email: email)
//        if let status = result?.emailSync.enabled {
//            gmailSync = status
//            gmailSyncInProgress = false
//        }
    }
    
    func enableGmailSync() async {
//        let result = await GoogleSyncModel.shared.enableGmailSync(authorizationCode: nil, email: email)
//        if let status = result?.emailSync.enabled, status == true {
//            gmailSync = status
//            gmailSyncInProgress = false
//        }
    }
    
    func disableGmailSync() async {
//        let result = await GoogleSyncModel.shared.disableGmailSync(email: email)
//        if let status = result?.emailSync.enabled, status == false {
//            gmailSync = status
//            gmailSyncInProgress = false
//        }
    }
    
    //MARK: - Calendar Sync Methods
    
    func checkForCalendarSync() async {
//        let result = await GoogleSyncModel.shared.checkForCalendarSync()
//        if let status = result {
//            calendarSync = status
//            calendarSyncInProgress = false
//        }
    }
    
    
    
    @ViewBuilder
    func header() -> some View {
        ZStack{
            HStack{
                Button {
                    withoutAnimation {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundStyle(.textTitle)
                }
                .padding(.leading, 10)
                Spacer()
            }
            HStack{
                Spacer()
                Text("GOOGLE ACCOUNT")
                    .foregroundStyle(.textTitle)
                    .font(Theme.textTitle)
                Spacer()
            }
        }
        .padding()
    }
    
    
    @ViewBuilder
    func pageTitle(text: String) -> some View {
        HStack{
            Text(text)
                .foregroundStyle(Color.chatPrimary)
                .font(Theme.chatTextTranscript)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    
    func signOut() async {
        self.inProgress = true
        defer {
            self.inProgress = false
        }
        
        GIDSignIn.sharedInstance.signOut()
        
        if gmailSync {
//            let result = await GoogleSyncModel.shared.disableGmailSync(email: email)
        }
        if calendarSync {
//            let result = await GoogleSyncModel.shared.disableCalendarSync(email: email)
        }
        
        
        withoutAnimation {
            isPresented = false
        }
        
    }
    
    
}

#Preview {
    GoogleSyncView(email: .constant(""), isPresented: .constant(true))
}
