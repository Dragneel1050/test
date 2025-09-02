//
//  HomeModel.swift
//  Corbo
//
//  Created by Agustín Nanni on 03/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import SwiftUI

enum homePermissionStates{
    case none, userData, location, contacts, google
}

@Observable
class HomeModel {
    static let shared = HomeModel()
    
    init() {
        showSiriTip = !ConfigModel.userDefaults().bool(forKey: siriTipClosedKey)
    }
    
    private let userDefaults = ConfigModel.userDefaults()
    private let siriTipClosedKey = "siriTipClosed"
    
    func reset() {
        permissionState = .none
        permissionsToBeRequested = [homePermissionStates]()
        activeTab = .network
        chatViewOpen = false
        feedbackViewOpen = false
        feedbackQuestionId = nil
        buttonBounds = nil
        showEntityTray = false
    }
    
    private(set) var permissionState = homePermissionStates.none
    private(set) var permissionsToBeRequested = [homePermissionStates]()
    
    var activeTab = availableTabs.network {
        didSet {
            while self.homeNavPath.count != 0 {
                self.homeNavPath.removeLast()
            }
        }
    }
    var chatViewOpen = false {
        didSet {
            if !chatViewOpen {
                self.chatViewModel = nil
            }
        }
    }
    var feedbackViewOpen = false {
        didSet {
            if !feedbackViewOpen {
                self.feedbackQuestionId = nil
            }
        }
    }
    var feedbackQuestionId: Int64? = nil
    var buttonBounds: CGRect? = nil
    var showEntityTray = false
    var homeNavPath = NavigationPath()
    var chatViewModel: ChatViewModel?
    var showSettings = false
    
    var storiesUsedViewOpen = false {
        didSet {
            if !storiesUsedViewOpen {
                self.storiesUsedViewPayload = nil
            }
        }
    }
    var storiesUsedViewPayload: questionDetailsResponse? = nil
    
    var showSiriTip: Bool {
        didSet {
            if !showSiriTip {
                userDefaults.setValue(true, forKey: siriTipClosedKey)
            }
        }
    }
    
    @MainActor
    func openChatView(chatViewOpen: Binding<Bool>) {
        self.chatViewModel = ChatViewModel(chatViewOpen: chatViewOpen)
        self.chatViewOpen = true
    }
    
    @MainActor
    func openPreviousSession(_ session: Session, chatViewOpen: Binding<Bool>) {
        self.chatViewModel = ChatViewModel(chatViewOpen: chatViewOpen, session: session)
        self.chatViewOpen = true
    }
    
    func openFeedbackSheet(_ questionId: Int64) {
        EventsModel.shared.track(ViewSubmitFeedback())
        self.feedbackQuestionId = questionId
        self.feedbackViewOpen = true
    }
    
    func openStoriesUsedSheet(_ payload: questionDetailsResponse) {
        EventsModel.shared.track(ViewStoriesUsed())
        self.storiesUsedViewPayload = payload
        self.storiesUsedViewOpen = true
    }
    
    func setNextEnqueuedPermission() {
        if self.permissionsToBeRequested.isEmpty {
            self.permissionState = .none
        } else {
            self.permissionState =  self.permissionsToBeRequested.removeFirst()
        }
    }
    
    func enqueuePermissionRequest(_ perm: homePermissionStates) {
        self.permissionsToBeRequested.append(perm)
    }
}
