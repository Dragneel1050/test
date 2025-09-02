//
import Contacts
import SwiftUI

@globalActor
actor ContactsModel {
    static let shared = ContactsModel()
    
    @AppStorage("contactsEnabled", store: ConfigModel.userDefaults()) private var contactsEnabled = false
    
    private var contactList: [basicContactWithStoryCount]? = nil
    
    private func importContactsFromApple() async -> [importContact] {
        var result: [importContact] = []
        
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey,
                    CNContactMiddleNameKey,
                    CNContactFamilyNameKey,
                    CNContactBirthdayKey,
                    CNContactNicknameKey,
                    CNContactOrganizationNameKey,
                    CNContactJobTitleKey,
                    CNContactNoteKey,
                    CNContactEmailAddressesKey,
                    CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        do {
            try store.enumerateContacts(with: request) {contact, _ in
                let serializableContact = serializableContact(contact)
                result.append(serializableContact)
            }
        } catch {
            AppLogs.defaultLogger.error("importContactsFromApple: \(error)")
        }
        
        return result
    }
    
    private func serializableContact(_ contact: CNContact) -> importContact {
        var emails: [contactEmailAddress] = []
        for address in contact.emailAddresses {
            let label = address.label != nil ? CNLabeledValue<NSString>.localizedString(forLabel: address.label!) : ""
            emails.append(contactEmailAddress(tag: label, value: address.value as String))
        }
        
        var phones: [contactPhoneNumber] = []
        for phone in contact.phoneNumbers {
            let label = phone.label != nil ? CNLabeledValue<NSString>.localizedString(forLabel: phone.label!) : ""
            phones.append(contactPhoneNumber(tag: label, value: phone.value.stringValue))
        }
        
        var importContactRequest = importContact(externalId: contact.identifier, firstName: contact.givenName)
        
        importContactRequest.middleName = contact.middleName.isEmpty ? nil : contact.middleName
        importContactRequest.lastName = contact.familyName.isEmpty ? nil : contact.familyName
        importContactRequest.nickname = contact.nickname.isEmpty ? nil : contact.nickname
        importContactRequest.notes = contact.note.isEmpty ? nil : contact.note
        importContactRequest.organizationName = contact.organizationName.isEmpty ? nil : contact.organizationName
        importContactRequest.jobTitle = contact.jobTitle.isEmpty ? nil : contact.jobTitle
        
        var birthdayDate: Date? = nil
        let gregorianCalendar = Calendar(identifier: .gregorian)
        if let birthdayComponents = contact.birthday {
            birthdayDate = gregorianCalendar.date(from: birthdayComponents)!
            importContactRequest.birthday = birthdayDate
        }
        
        if emails.count > 0 {
            importContactRequest.emailAddresses = emails
        }
        
        if phones.count > 0 {
            importContactRequest.phoneNumbers = phones
        }
        
        return importContactRequest
    }
    
    func syncContacts() async throws {
        let deviceId = await UIDevice.current.identifierForVendor
        let contacts = await self.importContactsFromApple()
        let payload = importContactBulkRequest(deviceId: deviceId?.uuidString, contacts: contacts)
        let serializedPayload = try JSONEncoder.apiEncoder.encode(payload)
        let compresedPayload = try (serializedPayload as NSData).compressed(using: .zlib)
        try await ApiModel.shared.importContactBulk(data: compresedPayload as Data)
        contactsEnabled = true
    }
    
    func refreshContacts() async throws {
        self.contactList = try await ApiModel.shared.listContacts().contactsList
    }
    
    func listContacts() async throws -> [basicContactWithStoryCount] {
        if contactList == nil {
            self.contactList = try await ApiModel.shared.listContacts().contactsList
        }
        
        return self.contactList!
    }
    
    func findContactById(_ id: Int64) -> basicContactWithStoryCount? {
        return self.contactList?.first(where: { $0.contactId == id })
    }
    
    func reset() {
        self.contactList = nil
    }
}
