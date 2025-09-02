//
//  GoogleSyncModel.swift
//  Corbo
//
//  Created by admin on 30/09/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import GoogleSignIn

enum GoogleSyncTypes: String, Codable {
    case gmail
    case calendar
}

enum GoogleSyncScopeTypes: String, Codable {
    case gmail = "https://www.googleapis.com/auth/gmail.readonly"
    
    // To be implemented in next release
//    case contacts = "https://www.googleapis.com/auth/contacts.readonly"
    
    case calendar = "https://www.googleapis.com/auth/calendar.readonly"
    case userinfo = "https://www.googleapis.com/auth/userinfo.email"
}

struct GoogleSyncModel {
    let email: String
}


@Observable
class GoogleSyncViewModel {
    
    static let shared = GoogleSyncViewModel()
    
    var gmailSyncEmail : String?
    var calendarSyncEmail : String?
    
    var scopes = [
        "openid",
        GoogleSyncScopeTypes.userinfo.rawValue,
        GoogleSyncScopeTypes.gmail.rawValue,
        
        // To be implemented in next release
//        GoogleSyncScopeTypes.contacts.rawValue,
        
        GoogleSyncScopeTypes.calendar.rawValue
        
    ]
    
    init() {
        Task {
            await getSyncConfigurations()
        }
    }
    
    func addScope(_ scope: String) {
        if !scopes.contains(scope) {
            scopes.append(scope)
        }
    }
    
    func removeScope(_ scope: String) {
        if let index = scopes.firstIndex(of: scope) {
            scopes.remove(at: index)
        }
    }
    
    
    
    func getSyncConfigurations() async {
        
        let syncStatus = ConfigModel.shared.getExternalSync()
        gmailSyncEmail = syncStatus?.emailSyncID
        calendarSyncEmail = syncStatus?.calendarSyncID
        print("syncStatus for email and calendar = \(syncStatus)")
    }
    
    
    
    
    
    
    
    
    
    //MARK: - Gmail Sync Methods
    
    func checkForGmailSync(email: String) async {
        
        do {
             let gmailSync = try await ApiModel.shared.getEmailSyncStatus()
//            self.gmailSync = gmailSync
            
        } catch let err {
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("\(err.localizedDescription)")
                await ToastsModel.shared.notifyError(message: "Error getting email sync status")
            }
        }
        
    }
    
    
    func enableGmailSync(authorizationCode: String?, email: String) async -> EmailSyncSuccessResponse? {
        
        do {
            return try await ApiModel.shared.enableEmailSync(authorizationCode: authorizationCode, email: email)
            
        } catch let err {
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("\(err.localizedDescription)")
                await ToastsModel.shared.notifyError(message: "Error enabling email sync")
            }
            return nil
        }
        
    }
    
    
    func disableGmailSync(email: String) async -> EmailSyncSuccessResponse? {
        
        do {
            return try await ApiModel.shared.disableEmailSyncStatus(email: email)
            
        } catch let err {
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("\(err.localizedDescription)")
                await ToastsModel.shared.notifyError(message: "Error disabling email sync")
            }
            return nil
        }
        
    }
    
    
    //MARK: - Calendar Sync Methods
    
    func checkForCalendarSync() async -> Bool? {
        do {
            let result = try await ApiModel.shared.prepareSettings()
            return result.calendarSync.isEmpty ? false : true
        } catch let err {
            if Task.isCancelled {
                return nil
            }
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("\(err.localizedDescription)")
                await ToastsModel.shared.notifyError(context: "ApiModel.shared.prepareSettings()", error: err )
            }
            return nil
        }
    }
    
    func enableCalendarSync(authorizationCode: String?, email: String) async -> Bool {
        do {
            try await ApiModel.shared.enableCalendarSync(authorizationCode: authorizationCode ?? "", email: email)
            return true
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("\(err.localizedDescription)")
                await ToastsModel.shared.notifyError(context: "ApiModel.shared.prepareSettings()", error: err )
            }
            return false
        }
    }
    
    func disableCalendarSync(email: String) async -> Bool {
        
        do {
            try await ApiModel.shared.disableCalendarSync(email: email)
            return true
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                await ToastsModel.shared.notifyError(context: "ApiModel.shared.disableCalendarSync()", error: err )
            }
            return false
        }
    }
    
    
    
    
    
}
