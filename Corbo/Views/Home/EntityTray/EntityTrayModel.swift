//
//  EntityTrayModel.swift
//  Corbo
//
//  Created by Agustín Nanni on 19/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

enum EntityTrayModelStates {
    case searchEntity, createContact
}

@Observable
class EntityTrayModel {
    let context: entityBindingContext
    
    init(context: entityBindingContext) {
        self.context = context
        self.searchText = ""
        
        self.searchTextEditEvents
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink{ value in
                if !self.working {
                    Task {
                        await self.searchContacts(value)
                    }
                }
            }
            .store(in: &cancellables)
    }
    var searchText: String {
        didSet {
            searchTextEditEvents.send(searchText)
        }
    }
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var searchTextEditEvents = PassthroughSubject<String, Never>()
    private(set) var working = false
    private(set) var state: EntityTrayModelStates = .searchEntity
    var sheetPresentationDetents: Set<PresentationDetent> {
        switch self.state {
        case .searchEntity:
            [.height(250)]
        case .createContact:
            [.height(400)]
        }
    }
    private(set) var contactResultList: [basicContactWithStoryCount] = []
    
    @MainActor
    func setState(_ state: EntityTrayModelStates) {
        self.state = state
    }
    
    func searchContacts(_ query: String) async {
        if query.isEmpty { return }
        defer {self.working = false}

        EventsModel.shared.track(NerSearch(searchText: query))
        do {
            let contacts = try await ContactsModel.shared.listContacts()
            let results = contacts.filter({ $0.contactName.lowercased().contains(query.lowercased()) })
            self.contactResultList = results
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                await ToastsModel.shared.notifyError(context: "EntityTrayModel.searchContacts()", error: err )
            }
        }
    }
    
    
    func bindContact(_ contact: basicContactWithStoryCount) async {
        self.working = true
        
        guard let name = context.entity.name else {
            AppLogs.defaultLogger.warning("bindContact: cant link entity with no name")
            return
        }
        
        do {
            if let storyId = context.storyId {
                try await ApiModel.shared.linkStoryEntityToContact(request: linkStoryEntityToContactRequest(storyId: storyId, entityName: name, contactId: contact.contactId))
            } else if let questionId = context.questionId {
                try await ApiModel.shared.linkQuestionEntityToContact(request: linkQuestionEntityToContactRequest(questionId: questionId, entityName: name, contactId: contact.contactId))
            } else {
                AppLogs.defaultLogger.warning("bindContact: Unable to find what to bind to")
                self.working = false
                return
            }
            
//            NavigationModel.shared.storeRecentLink(name: name, contactId: contact.contactId)
            EventsModel.shared.track(NerEntityBound())
            await NavigationModel.shared.closeEntityBinding()
            await ToastsModel.shared.displayMessage(text: "Contact Linked!", bgColor: .green, textColor: .textPrimary)
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                await ToastsModel.shared.notifyError(context: "EntityTrayModel.bindContact", error: err)
            }
            self.working = false
        }
    }
    
    func createAndBindContact(_ contact: createContactRequest) async {
        self.working = true
        
        guard let name = context.entity.name else {
            AppLogs.defaultLogger.warning("createAndBindContact: cant link entity with no name")
            return
        }
        
        do {
            var type: String?
            let entityId: Int64? = {
                if let storyId = context.storyId {
                    type = "story"
                    return storyId
                } else if let questionId = context.questionId {
                    type = "question"
                    return questionId
                } else {
                    return nil
                }
            }()
            
            guard let entityId = entityId else {
                AppLogs.defaultLogger.warning("createAndBindContact: Unable to find what to bind to")
                return
            }
            
            let response = try await ApiModel.shared.createContactEntity(request: CreateEntityContactRequest(contact: contact, entity: createContactEntityRequest(entityName: context.entity.name, contextType: type, externalId: entityId)))
            
            if let contactId = response.externalId {
//                NavigationModel.shared.storeRecentLink(name: name, contactId: contactId)
                Task{
                    try? await ContactsModel.shared.refreshContacts()
                }
            }
            EventsModel.shared.track(NerEntityBound())
            EventsModel.shared.track(NerContactCreated())
            await NavigationModel.shared.closeEntityBinding()
            await ToastsModel.shared.displayMessage(text: "Contact Linked!", bgColor: .green, textColor: .textPrimary)
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                await ToastsModel.shared.notifyError(context: "EntityTrayModel.createAndBindContact", error: err)
            }
            self.working = false
        }
    }

}
