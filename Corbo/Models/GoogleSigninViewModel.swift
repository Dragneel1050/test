//
//  GoogleSigninModel.swift
//  Corbo
//
//  Created by admin on 08/10/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import GoogleSignIn
import SwiftUI

class GoogleSignInViewModel: ObservableObject {
    @Published var emailAccountSignedIn = false
    @Published var calendarAccountSignedIn = false
    
    let emailSigninInstance = GIDSignIn.sharedInstance
    let calendarSigninInstance = GIDSignIn.sharedInstance
    
    private var emailScope = ["https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/gmail.readonly"]
    private var calendarScope = ["https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/calendar.readonly"]
    
    func signInEmailAccount(rootViewController: UIViewController) {
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: "Sign in with email account",
            additionalScopes: emailScope
        ) { result, error in
            guard error == nil else {
                print("Sign in with email account failed: \(error!.localizedDescription)")
                return
            }
            
            print("Successfully signed in with email account!")
            self.emailAccountSignedIn = true
        }
    }
    
    func signInCalendarAccount(rootViewController: UIViewController) {
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: "Sign in with calendar account",
            additionalScopes: calendarScope
        ) { result, error in
            guard error == nil else {
                print("Sign in with calendar account failed: \(error!.localizedDescription)")
                return
            }
            
            print("Successfully signed in with calendar account!")
            self.calendarAccountSignedIn = true
        }
    }
    
    func signOutEmailAccount() {
        GIDSignIn.sharedInstance.signOut()
        emailAccountSignedIn = false
        print("Signed out from first account.")
    }
    
    func signOutCalendarAccount() {
        GIDSignIn.sharedInstance.signOut()
        calendarAccountSignedIn = false
        print("Signed out from second account.")
    }
}
