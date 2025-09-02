//
//  HomePermissionsWrapper.swift
//  Corbo
//
//  Created by Agustín Nanni on 08/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI
import CoreLocation
import AppAuthCore

struct HomePermissionsWrapper: View {
    @State private var model = HomeModel.shared
    @State private var locationModel = LocationModel.shared
    @State private var firstName = AuthModel.shared.currentUserData?.firstName ?? ""
    @State private var lastName = AuthModel.shared.currentUserData?.lastName ?? ""
    @State private var email = AuthModel.shared.currentUserData?.email ?? ""
    @State private var shouldProvideData = false
    @State private var working = false
    
    var body: some View {
        switch model.permissionState {
        case .none:
            Home()
        case .contacts:
            contactsSync()
                .background{
                    Background()
                }
        case .location:
            location()
                .background{
                    Background()
                }
        case .userData:
            userData()
                .background{
                    Background()
                }
        case .google:
            GoogleAccountSyncView()
                .background{
                    Background()
                }
        }
    }
    
    func contactsSync() -> some View {
        VStack(spacing: 40){
            OnboardingTopNav()
            Spacer()
                .frame(height: 10)
            Text("Sync Your Contacts")
                .font(Theme.barlowRegular)
                .foregroundStyle(.textTitle)
            HStack{
                Image("Glyph=Phone")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                Image("Glyph=ArrowForward")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                Image("Glyph=Contacts")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            }
            .foregroundStyle(.iconPrimary)
            Text("We’ll use this to help create connections, insights and the start of the new super powers we help create.")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textInformation)
                .multilineTextAlignment(.center)
            FormButton(action: syncContacts, label: String(localized: "Sync Now"), working: $working)
            Text("Corbo will not share or message your contacts without you taking explicit actions in the app.")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textInformation)
                .multilineTextAlignment(.center)
            SkipForNowButton(action: skipContactsSync, working: $working)
            Spacer()
        }
        .padding(.horizontal, 30)
    }
    
    func userData() -> some View {
        VStack(spacing: 40){
            OnboardingTopNav(onBack: {
                if firstName.isEmpty || lastName.isEmpty || email.isEmpty {
                    Task {
                        await ToastsModel.shared.displayMessage(text: "Please fill all fields")
                    }
                    return
                }
                HomeModel.shared.setNextEnqueuedPermission()
            })
            Spacer()
                .frame(height: 10)
            Text("Tell Us About You")
                .font(Theme.barlowRegular)
                .foregroundStyle(.textTitle)
            VStack(alignment: .leading, spacing: 25){
                Text("Your Name")
                    .font(Theme.formLabelTitle)
                    .foregroundStyle(.textHeader)
                    .padding(.horizontal, 7)
                FormTextInput(placeholder: "First Name", text: $firstName)
                FormTextInput(placeholder: "Last Name", text: $lastName)
                Text("Your Email Address")
                    .font(Theme.formLabelTitle)
                    .foregroundStyle(.textHeader)
                    .padding(.horizontal, 7)
                    .keyboardType(.emailAddress)
                FormTextInput(placeholder: "user@domain.com", text: $email)
            }
            .padding()
            Spacer()
            FormButton(action: submitData, label: "Continue", working: $working)
            Spacer()
        }
    }
    
    func location() -> some View {
        VStack(spacing: 10){
            OnboardingTopNav()
            Spacer()
                .frame(height: 10)
            Text("The power of context")
                .font(Theme.barlowRegular)
                .foregroundStyle(.textTitle)
            Text("Enable location access for assistance with places and enhanced experiences")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textSecondary)
                .padding(.horizontal)
            VStack(alignment: .leading, spacing: 25){
                Spacer()
                    Image(systemName: "location.circle")
                    .font(.system(size: 150))
                    .foregroundStyle(.chatPrimary)
                    .background{
                        Circle()
                            .stroke(Color.borderPrimary, lineWidth: 1)
                            .fill(Color.surfaceApp)
                    }
                Spacer()
            }
            .padding()
            Spacer()
            FormButton(action: locationModel.requestPermission, label: "Allow", working: $working)
            Spacer()
        }
        .onChange(of: locationModel.locationStatus, { _, new in
            handleLocationChange(new: new)
        })
    }
    
    func skipContactsSync() {
        ConfigModel.shared.setLastContactInteractionDate()
        EventsModel.shared.track(ContactsSyncSkipped())
        model.setNextEnqueuedPermission()
    }
    
    func syncContacts() async {
        do {
            try await ContactsModel.shared.syncContacts()
            EventsModel.shared.track(ContactsSyncTriggered())
            model.setNextEnqueuedPermission()
            ConfigModel.shared.setLastContactInteractionDate()
            
            ToastsModel.shared.displayMessage(text: "Contacts synced successfully.", bgColor: .green, textColor: .textPrimary)
            
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("syncContacts: \(err)")
                ToastsModel.shared.notifyError(context: String(localized: "HomePermissionsWrapper.syncContacts"), error: err)
            }
        }
    }
    
    func submitData() async {
        do {
            try await AuthModel.shared.saveUserData(first: self.firstName, last: self.lastName, email: self.email)
            model.setNextEnqueuedPermission()
            EventsModel.shared.track(UserDataSaved())
        }
        catch AuthErrors.EmptyNameOrEmail {
            ToastsModel.shared.notifyError(message: "Please fill out the fields to proceed.", context: "HomePermissionsWrapper.EmptyNameOrEmail")
        }
        catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("submitData: \(err)")
                ToastsModel.shared.notifyError(context: "HomePermissionsWrapper.saveUserData", error: err )
            }
        }
    }
    
    func handleLocationChange(new: CLAuthorizationStatus?) {
        switch new {
        case .notDetermined:
            return
        case .restricted, .denied:
            EventsModel.shared.track(LocationPermisionResponse(response: "Denied"))
            model.setNextEnqueuedPermission()
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            EventsModel.shared.track(LocationPermisionResponse(response: "Authorized"))
            model.setNextEnqueuedPermission()
        case nil:
            return
        case .some(_):
            return
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


fileprivate struct GoogleAccountSyncView: View {
    @EnvironmentObject private var delegate: AppDelegate
    @State private var requestInProgress = false
    @State private var model = HomeModel.shared
    
    @State private var sharedCalendarSync: Bool = false
    @State private var contactsSync: Bool = true
    
    @State private var emailSyncID : String?
    @State private var calendarSyncID : String?
    
    @State private var syncType : GoogleSyncScopeTypes?
    
    
    var body: some View {
        VStack(){
            OnboardingTopNav()
            Spacer()
                .frame(height: 60)
            Text("Sign In to Your Google Account")
                .font(Theme.barlowRegular)
                .foregroundStyle(.textPrimary)
            
            Spacer()
                .frame(height: 40)
            
            Text("We’ll import and use your email, events and contacts as stories to make Corbo smarter when answering your questions.")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textInformation)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .padding(.bottom, 30)
            
            SyncOptionsView(iconName: "Gmail", title: "Gmail", desc: "Import your Email", inProgress: $requestInProgress, connectedID : $emailSyncID) {
                syncType = .gmail
                delegate.requestGoogleSigninAuth(scope: .gmail)
            }
            
            SyncOptionsView(iconName: "GoogleCalendar", title: "Calendar", desc: "Import your Calendars", inProgress: $requestInProgress, connectedID : $calendarSyncID) {
                syncType = .calendar
                delegate.requestGoogleSigninAuth(scope: .calendar)
            }
            
            AppDivider(color: .borderForm)
                .padding(.bottom, 30)
            
            
            Text("Corbo will not share your calendar without you taking explicit actions in the app.")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textInformation)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
                .padding(.horizontal, 20)
                .lineLimit(nil)
                .minimumScaleFactor(0.7)
            
            if (emailSyncID != nil) || (calendarSyncID != nil) {
                Button {
                    
                    EventsModel.shared.track(GoogleSigninCompleted())
                    ConfigModel.shared.updateExternalSync(skipOnboarding: true)
                    model.setNextEnqueuedPermission()
//                    Task {
//                        ToastsModel.shared.displayMessage(text: "Sync Completed", bgColor: .green, textColor: .textPrimary)
//                    }
                } label: {
                    Text("Done")
                        .frame(width: 200, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.borderFormFocus, lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
            } else {
                SkipForNowButton(action: handleSkip, working: $requestInProgress)
            }
            
            Spacer()
            
        }
        .padding(.horizontal, 16)
        .onReceive(delegate.googleSigninStatesProducer, perform: { value in
            switch value {
            case .working:
                self.requestInProgress = true
            case .done:
                self.requestInProgress = false
                handleDone()
            case .failed:
                self.requestInProgress = false
            }
        })
        .onAppear() {
            checkforSync()
        }
    }
    
    
    //MARK: - Custom Functions
    
    func handleSkip() {
        EventsModel.shared.track(GoogleSigninSkipped())
        ConfigModel.shared.updateExternalSync(skipOnboarding: true)
        model.setNextEnqueuedPermission()
    }
    
    func handleDone() {
        if let type = syncType {
            switch type {
            case .gmail:
                checkforSync()
            case .calendar:
                checkforSync()
            case .userinfo:
                break
            }
        }
    }
    
    func checkforSync() {
        let syncDetail = ConfigModel.shared.getExternalSync()
        
        if let emailID = syncDetail?.emailSyncID {
            self.emailSyncID = emailID
        }
        
        if let calendarID = syncDetail?.calendarSyncID {
            self.calendarSyncID = calendarID
        }
        
    }
    
}

struct SyncOptionsView : View {
    
    var iconName : String
    var title : String
    var desc : String
    
    @Binding var inProgress : Bool
    @Binding var connectedID : String?
    
    var onClick : (() -> Void)
    
    
    var body: some View {
        HStack {
            Image(iconName)
                .resizable()
                .frame(width: 36, height: 36)
                .padding(.leading)
                .padding(.trailing, 10)
            VStack {
                HStack {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .foregroundStyle(.textPrimary)
                            .font(.system(size: 17, weight: .regular))
                        if let id = connectedID {
                            Text(id)
                                .foregroundStyle(.textSecondary)
                                .font(.system(size: 12, weight: .regular))
                        } else {
                            Text(desc)
                                .foregroundStyle(.textSecondary)
                                .font(.system(size: 12, weight: .regular))
                        }
                    }
                    .layoutPriority(1)
                    Spacer()
                    
                    if inProgress {
                        ProgressView()
                            .frame(width: 30, height: 60)
                            .layoutPriority(0)
                            .tint(.chatPrimary)
                            .padding(.trailing, 20)
                    } else {
                        if connectedID != nil {
                            Image("Glyph=GoogleCheckmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 60)
                                .padding(.trailing, 20)
                        } else {
                            Button {
                                onClick()
                            } label: {
                                HStack {
                                    Text("Sign In ")
                                        .font(Theme.formLabelTitle)
                                        .foregroundStyle(.chatTextThinking)
                                    Image("Glyph=ChevronRight")
                                }
                            }
                            .frame(height: 60)
                            .padding(.trailing, 20)
                        }
                    }
                }
            }
            
        }
        .background(.chatTextBot)
        .cornerRadius(10)
        .padding(.bottom, 20)
    }
}


#Preview {
    VStack{
        @StateObject var delegate = AppDelegate()
        HomePermissionsWrapper()
            .environmentObject(delegate)
    }
}
