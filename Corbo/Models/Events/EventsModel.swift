//
//  EventsModel.swift
//  Corbo
//
//  Created by Agustín Nanni on 15/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import Combine
import Mixpanel

@globalActor
actor EventsModel {
    static let shared = EventsModel()
    private let eventQueue = PassthroughSubject<AnalyticsEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Mixpanel.initialize(token: "2ba9a4fe2f86bfea24ff4f2199a9ab90", trackAutomaticEvents: true)
        Task{
            await self.setupDelivery()
        }
    }
    
    func identifyUser(with payload: verifyCodeResponse) {
        Mixpanel.mainInstance().identify(distinctId: payload.userId.formatted())
        var properties = [String: MixpanelType]()
        properties["$phone"] = payload.phoneNumber
        if let userData = payload.userData {
            properties["$name"] = userData.firstName + " " + userData.lastName
            properties["$email"] = userData.email
        }
        Mixpanel.mainInstance().people.set(properties: properties)
    }
    
    func logout() {
        Mixpanel.mainInstance().reset()
    }
    
    private func sendToMixPanel(_ src: AnalyticsEvent) {
        Mixpanel.mainInstance().track(event: src.name, properties: src.properties())
    }
    
    private func setupDelivery() {
        eventQueue.sink(receiveValue: { event in
            self.sendToMixPanel(event)
        })
        .store(in: &cancellables)
    }

    nonisolated func track(_ src: AnalyticsEvent) {
        self.eventQueue.send(src)
    }
}

protocol AnalyticsEvent {
    var name: String { get }
    func properties() -> [String: String]?
}
