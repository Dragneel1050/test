//
//  GoogleAccountSyncView_NI.swift
//  Corbo
//
//  Created by admin on 10/10/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct GoogleAccountSyncView_NI: View {
    @EnvironmentObject private var delegate: AppDelegate
    @State private var working = false
    @State private var model = HomeModel.shared
    
    @State private var gmailSync: Bool = true
    @State private var calendarSync: Bool = true
    @State private var sharedCalendarSync: Bool = false
    @State private var contactsSync: Bool = true
    
    var body: some View {
        VStack(){
            OnboardingTopNav()
            Spacer()
                .frame(height: 60)
            Text("Sign In to Your Google Account")
                .font(Theme.barlowRegular)
                .foregroundStyle(.textPrimary)
            
            Spacer()
                .frame(height: 20)
            
            Text("We’ll import and use your email, events and contacts as stories to make Corbo smarter when answering your questions.")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textInformation)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .padding(.bottom, 10)
            
            
            VStack {
                
//                SyncOptionsView(iconName: "Gmail", title: "Gmail", desc: "Import your Email", valueToBindWithToggle: $gmailSync, waitForResponse: .constant(false), bottomDevider: true)
//                
//                SyncOptionsView(iconName: "GoogleCalendar", title: "Calendar", desc: "Import your Calendars", valueToBindWithToggle: $calendarSync, waitForResponse: .constant(false), bottomDevider: false)
                
                
                
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
            .background(.chatTextBot)
            .padding(.bottom, 20)
            
            ZStack {
                Button{
                    
                    gmailSync ? GoogleSyncViewModel.shared.addScope(GoogleSyncScopeTypes.gmail.rawValue) : GoogleSyncViewModel.shared.removeScope(GoogleSyncScopeTypes.gmail.rawValue)
                    calendarSync ? GoogleSyncViewModel.shared.addScope(GoogleSyncScopeTypes.calendar.rawValue) : GoogleSyncViewModel.shared.removeScope(GoogleSyncScopeTypes.calendar.rawValue)
                    
                    // To be implemented in next release
//                    contactsSync ? GoogleSyncModel.shared.addScope(GoogleSyncScopeTypes.contacts.rawValue) : GoogleSyncModel.shared.removeScope(GoogleSyncScopeTypes.contacts.rawValue)
                    
//                    delegate.requestGoogleSigninAuth()
                    
                } label: {
                    HStack{
                        Image("Glyph=Google")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Sign in with Google")
                            .foregroundStyle(Color.chatTextThinking)
                            .font(.system(size: 15, weight: .bold))
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 20)
                    .background{
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.chatTextBot)
                            .stroke(.iconSecondary, style: StrokeStyle(lineWidth: 2))
                    }
                }
                .opacity(working ? 0 : 1)
                .disabled(working)
                
                ProgressView()
                    .tint(Color.chatPrimary)
                    .opacity(working ? 1 : 0)
            }
            .padding(.bottom, 30)
            
            Text("Corbo will not share your calendar without you taking explicit actions in the app.")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textInformation)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
                .padding(.horizontal, 20)
                .lineLimit(nil)
                .minimumScaleFactor(0.7)
            
            SkipForNowButton(action: handleSkip, working: $working)
            
            Spacer()
            
        }
        .padding(.horizontal, 16)
        .onReceive(delegate.googleSigninStatesProducer, perform: { value in
            switch value {
            case .working:
                self.working = true
            case .done:
                self.working = false
                handleDone()
            case .failed:
                self.working = false
            }
        })
    }
    
    func handleSkip() {
        EventsModel.shared.track(GoogleSigninSkipped())
        ConfigModel.shared.updateExternalSync(skipOnboarding: true)
        model.setNextEnqueuedPermission()
    }
    
    func handleDone() {
        EventsModel.shared.track(GoogleSigninCompleted())
        ConfigModel.shared.updateExternalSync(skipOnboarding: true)
        model.setNextEnqueuedPermission()
        Task {
            ToastsModel.shared.displayMessage(text: "Google Signin Successfully.", bgColor: .green, textColor: .textPrimary)
        }
        
    }
}

fileprivate struct SkipForNowButton: View {
    let action: () -> Void
    @Binding var working: Bool
    
    var body: some View {
        ZStack{
            Button(action: action, label: {
                Text("Skip for now")
                    .font(.system(size: 18))
                    .foregroundStyle(.textSecondary)
            })
                .disabled(working)
                .opacity(working ? 0 : 1)
            ProgressView()
                .tint(.chatPrimary)
                .opacity(working ? 1 : 0)
        }
    }
}



//
//struct SyncOptionsView : View {
//    
//    var iconName : String
//    var title : String
//    var desc : String
//    @Binding var valueToBindWithToggle : Bool
//    @Binding var waitForResponse : Bool
//    var bottomDevider : Bool
//    
//    
//    var body: some View {
//        HStack {
//            Image(iconName)
//                .resizable()
//                .frame(width: 36, height: 36)
//                .padding(.leading)
//                .padding(.trailing, 10)
//            VStack {
//                HStack {
//                    
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text(title)
//                            .foregroundStyle(.textPrimary)
//                            .font(.system(size: 17, weight: .regular))
//                        Text(desc)
//                            .foregroundStyle(.textSecondary)
//                            .font(.system(size: 12, weight: .regular))
//                    }
//                    .layoutPriority(1)
//                    Spacer()
//                    if waitForResponse {
//                        ProgressView()
//                            .frame(width: 31, height: 31)
//                            .padding()
//                            .layoutPriority(0)
//                            .foregroundStyle(.chatPrimary)
//                    } else {
//                        Toggle("", isOn: $valueToBindWithToggle)
//                            .padding()
//                            .layoutPriority(0)
//                    }
//                }
//                if bottomDevider {
//                    AppDivider(color: .borderForm)
//                }
//            }
//            
//        }
//    }
//}


#Preview {
    GoogleAccountSyncView_NI()
}
