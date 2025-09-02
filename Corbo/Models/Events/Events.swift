//
//  Events.swift
//  Corbo
//
//  Created by Agustín Nanni on 15/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation

struct ChatInteraction: AnalyticsEvent {
    let name = "ChatInteraction"
    let type: CNNModelResultTypes?
    
    func properties() -> [String: String]? {
        return [
            "$type": type?.value ?? "unknown-nil"
        ]
    }
}

struct UserDataCreated: AnalyticsEvent {
    let name = "UserDataCreated"
    
    func properties() -> [String: String]? {
        return nil
    }
}

struct ErrorShown: AnalyticsEvent {
    let name = "ErrorShown"
    let errorText: String
    let context: String?
    let errorDetails: String?
    
    init(errorText: String, context: String? = nil, errorDetails: String? = nil) {
        self.errorText = errorText
        self.context = context
        self.errorDetails = errorDetails
    }

    func properties() -> [String : String]? {
        var result = [String : String]()
        result["$errorText"] = errorText
        if let context = context {
            result["$context"] = context
        }
        if let errorDetails = errorDetails {
            result["$errorDetails"] = errorDetails
        }
        
        return result
    }
}

struct ViewChatPopup: AnalyticsEvent {
    let name = "ViewChatPopup"
    func properties() -> [String : String]? {
        nil
    }
}

struct ViewNetwork: AnalyticsEvent {
    let name = "ViewNetwork"
    func properties() -> [String : String]? {
        nil
    }
}

struct ViewStories: AnalyticsEvent {
    let name = "ViewStories"
    func properties() -> [String : String]? {
        nil
    }
}

struct ChatSessionStarted: AnalyticsEvent {
    let name = "ChatSessionStarted"
    let date = Date()
    
    func properties() -> [String : String]? {
        [
            "$startDate": date.formatted()
        ]
    }
}

struct ChatSessionRestored: AnalyticsEvent {
    let name = "ChatSessionRestored"
    let date = Date()
    
    func properties() -> [String : String]? {
        [
            "$date": date.formatted()
        ]
    }
}

struct ChatSessionEnded: AnalyticsEvent {
    let name = "ChatSessionEnded"
    let dateStart: Date
    let dateEnd: Date
    
    
    
    func properties() -> [String : String]? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.hour, .minute, .second]
        
        return [
            "$startDate": dateStart.formatted(),
            "$endDate": dateEnd.formatted(),
            "$elapsed": formatter.string(from: dateEnd.timeIntervalSince(dateStart)) ?? ""
        ]
    }
}

struct PhoneLoginEvent: AnalyticsEvent {
    let name = "PhoneLogin"
    let phoneNumber: String
    
    func properties() -> [String: String]? {
        return [
            "$phoneNumber": phoneNumber
        ]
    }
}

struct SmsCodeResend: AnalyticsEvent {
    let name = "SmsCodeResend"
    let phoneNumber: String
    
    func properties() -> [String: String]? {
        return [
            "$phoneNumber": phoneNumber
        ]
    }
}

struct SmsCodeVerification: AnalyticsEvent {
    let name = "SmsCodeVerification"
    let phoneNumber: String
    
    func properties() -> [String: String]? {
        return [
            "$phoneNumber": phoneNumber
        ]
    }
}

struct UserDataSaved: AnalyticsEvent {
    let name = "UserDataSaved"

    func properties() -> [String: String]? {
        return nil
    }
}


struct ContactsSyncTriggered: AnalyticsEvent {
    let name = "ContactsSyncTriggered"

    func properties() -> [String: String]? {
        return nil
    }
}

struct ContactsSyncSkipped: AnalyticsEvent {
    let name = "ContactsSyncSkipped"

    func properties() -> [String: String]? {
        return nil
    }
}

struct GmailSyncSkipped: AnalyticsEvent {
    let name = "GmailSyncSkipped"

    func properties() -> [String: String]? {
        return nil
    }
}

struct LocationPermisionResponse: AnalyticsEvent {
    let name = "LocationPermisionResponse"
    let response: String

    func properties() -> [String: String]? {
        return [
            "$response": response
        ]
    }
}

struct ViewStoriesUsed: AnalyticsEvent {
    let name = "ViewStoriesUsed"

    func properties() -> [String: String]? {
        return nil
    }
}

struct ViewSubmitFeedback: AnalyticsEvent {
    let name = "ViewSubmitFeedback"

    func properties() -> [String: String]? {
        return nil
    }
}

struct StoryCreated: AnalyticsEvent {
    let name = "StoryCreated"
    let source: String

    func properties() -> [String: String]? {
        return [
            "$source": source
        ]
    }
}

struct NerSearch: AnalyticsEvent {
    let name = "NerSearch"
    let searchText: String

    func properties() -> [String: String]? {
        return [
            "$searchText": searchText
        ]
    }
}

struct ViewNerBindingTray: AnalyticsEvent {
    let name = "ViewNerBindingTray"

    func properties() -> [String: String]? {
        return nil
    }
}

struct ViewNerContactDetails: AnalyticsEvent {
    let name = "ViewNerContactDetails"

    func properties() -> [String: String]? {
        return nil
    }
}

struct NerContactCreated: AnalyticsEvent {
    let name = "NerContactCreated"

    func properties() -> [String: String]? {
        return nil
    }
}

struct NerEntityBound: AnalyticsEvent {
    let name = "NerEntityBound"

    func properties() -> [String: String]? {
        return nil
    }
}

struct GoogleSigninSkipped: AnalyticsEvent {
    let name = "GoogleSigninSkipped"

    func properties() -> [String: String]? {
        return nil
    }
}

struct GoogleSigninCompleted: AnalyticsEvent {
    let name = "GoogleSigninCompleted"

    func properties() -> [String: String]? {
        return nil
    }
}
