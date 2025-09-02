//
//  ConfigModel.swift
//  Corbo
//
//  Created by Agustín Nanni on 09/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation

enum InputModes: String, CaseIterable {
    case Voice = "Voice"
    case Text = "Text"
}

class ConfigModel {
    static let shared = ConfigModel()
    static let suiteName = "group.settings.com.nomdevelopment.Corbo"

    private let lastContactInteractionKey = "lastContactInteractionKey"
    
    private let syncKey = "savedExternalSync"
    
    static let inputModeKey = "inputModeKey"
    
    func findLastContactInteractionDate() -> Date? {
        let data = ConfigModel.userDefaults().double(forKey: lastContactInteractionKey)
        if data != 0 {
            return Date(timeIntervalSince1970: TimeInterval(floatLiteral: data))
        }
        return nil
    }
    
    func setLastContactInteractionDate() {
        ConfigModel.userDefaults().setValue(Date.now.timeIntervalSince1970, forKey: lastContactInteractionKey)
    }
    
    
    //MARK: - ExternalSync
    // Save ExternalSync to UserDefaults
    func saveExternalSync(_ sync: ExternalSync) {
        if let encodedData = try? JSONEncoder().encode(sync) {
            ConfigModel.userDefaults().set(encodedData, forKey: syncKey)
        }
    }
    
    // Retrieve ExternalSync from UserDefaults
    func getExternalSync() -> ExternalSync? {
        if let savedData = ConfigModel.userDefaults().data(forKey: syncKey) {
            if let decodedSync = try? JSONDecoder().decode(ExternalSync.self, from: savedData) {
                return decodedSync
            }
        }
        return nil
    }
    
    // Update ExternalSync with specific fields
    func updateExternalSync(emailSyncID: String? = nil, calendarSyncID: String? = nil, skipOnboarding: Bool? = nil) {
        var sync = getExternalSync() ?? ExternalSync()
        sync.update(emailSyncID: emailSyncID, calendarSyncID: calendarSyncID, skipOnboarding: skipOnboarding)
        saveExternalSync(sync)
    }
    
    
    
    
    func findInputMode() -> InputModes {
        if let config = ConfigModel.userDefaults().string(forKey: ConfigModel.inputModeKey) {
            return InputModes(rawValue: config)!
        }
        
        return InputModes.Voice
    }
    
    static func userDefaults() -> UserDefaults {
        return UserDefaults(suiteName: suiteName)!
    }
    
    static func reset() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
    
    static func buildSharedByText() -> String {
        var userName: String? {
            let first = AuthModel.shared.currentUserData?.firstName
            let last = AuthModel.shared.currentUserData?.lastName
            
            if first != nil && last != nil {
                return first! + " " + last!
            }
            
            return nil
        }
        
        var result = "\n\nShared from Corbo https://corbo.ai"
        if let userName = userName {
            result += " by " + userName
        }
        
        return result
    }
}




// 1. Define the ExternalSync struct with optional properties
struct ExternalSync: Codable {
    var emailSyncID: String?
    var calendarSyncID: String?
    var skipOnboarding: Bool?

    // 2. Provide an update function
    mutating func update(emailSyncID: String? = nil, calendarSyncID: String? = nil, skipOnboarding: Bool? = nil) {
        if let newEmailSyncID = emailSyncID {
            newEmailSyncID == "" ? (self.emailSyncID = nil) : (self.emailSyncID = newEmailSyncID)
        }
        if let newCalendarSyncID = calendarSyncID {
            newCalendarSyncID == "" ? (self.calendarSyncID = nil) : (self.calendarSyncID = newCalendarSyncID)
        }
        if let newSkipOnboarding = skipOnboarding {
            self.skipOnboarding = newSkipOnboarding
        }
    }
}
