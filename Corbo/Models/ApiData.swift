//

import Foundation

struct emptyResponse: Codable {}

struct errorMessage: Codable, Error {
    let errorMessage: String?
}

struct userData: Codable {
    let firstName: String
    let lastName: String
    let email: String
}

struct refreshTokenRequest: Codable {
    let refreshToken: String
}

struct verifyCodeResponse: Codable {
    let token: String
    let refreshToken: String
    let userData: userData?
    let userId: Int64
    let phoneNumber: String
}

struct phoneNumberLoginRequest: Codable {
    let phoneNumber: String
}

struct verifyCodeRequest: Codable {
    let phoneNumber: String
    let code: String
}

struct whisperAudioResponse: Codable {
    let fileSize: String
    let text: String
    let recordDuration: String
    let languaje: String
    let tokensUsed: Int64
    let estimatedCost: String
    let operationTime: operationTime
}

struct operationTime: Codable {
    let parseMultipartFile: String
    let externalServiceCall: String
    let fullTime: String
}

struct askWithStreamChunkResponse: Codable {
    let data: String?
    let questionId: Int64?
    let sessionId: Int64?
    let entityList: [wordEntity]?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decodeIfPresent(String.self, forKey: .data)
        self.questionId = try container.decodeIfPresent(Int64.self, forKey: .questionId)
        self.sessionId = try container.decodeIfPresent(Int64.self, forKey: .sessionId)
        self.entityList = try container.decodeIfPresent([wordEntity].self, forKey: .entityList)
    }
}

struct askRequest: Codable {
    let question: String
    let sessionId: Int64?
    let searchContactOnly: Bool
}

struct listSessionResponse: Codable {
    let sessionList: [Session]
}

struct Session: Codable {
    let id: Int64?
    let userAccountId: Int64?
    var title: String?
    let createdTime: Date?
}

struct storyWithSimilarity: Codable, Hashable, Identifiable {
    let id: Int64?
    var content: String?
    let userAccountId: Int64?
    let createdTime: Date?
    let lastModifiedTime: Date?
    let similarity: Double?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.userAccountId = try container.decodeIfPresent(Int64.self, forKey: .userAccountId)
        self.createdTime = try container.decodeIfPresent(Date.self, forKey: .createdTime)
        self.lastModifiedTime = try container.decodeIfPresent(Date.self, forKey: .lastModifiedTime)
        self.similarity = try container.decodeIfPresent(Double.self, forKey: .similarity)
    }
}

struct promptMessage: Codable {
    let role: String
    let content: String
}

struct questionTimings: Codable {
    let obtainQuestionEmbeddings: String?
    let searchSimilarStories: String?
    let listPreviousInteractions: String?
    let rephraseQuestion: String?
    let askQuestion: String?
    let relativeFirstResponseChunk: String?
    let absoluteFirstResponseChunk: String?
    let fullResponseTime: String?
}

struct usage: Codable {
    let prompt_tokens: Int?
    let completion_tokens: Int?
    let total_tokens: Int?
}

struct questionContext: Codable {
    let similarityList: [storyWithSimilarity]?
    let similarityThreshold: Float64?
    let model: String?
    let temperature: Float64?
    let promptMessages: [promptMessage]?
    let questionTimings: questionTimings?
    let tokenUsage: usage?
    let rephraseResponse: String?
    let requestSize: String?
}

struct Question: Codable {
    let id: Int64?
    let userAccountId: Int64?
    let question: String?
    let answer: String?
    let createdTime: Date?
    let context: questionContext?
    let session: Session?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.userAccountId = try container.decodeIfPresent(Int64.self, forKey: .userAccountId)
        self.question = try container.decodeIfPresent(String.self, forKey: .question)
        self.answer = try container.decodeIfPresent(String.self, forKey: .answer)
        self.createdTime = try container.decodeIfPresent(Date.self, forKey: .createdTime)
        self.context = try container.decodeIfPresent(questionContext.self, forKey: .context)
        self.session = try container.decodeIfPresent(Session.self, forKey: .session)
    }
}

struct listSessionQuestionsRequest: Codable {
    let sessionId: Int64?
}

struct listSessionQuestionResponse: Codable {
    let session: Session?
    let questionList: [Question]?
}

struct updateApnsDeviceTokenRequest: Codable {
    let token: String?
}

struct importContact: Codable {
    let externalId: String
    let firstName: String
    
    var middleName: String?
    var lastName: String?
    var nickname: String?
    var notes: String?
    var organizationName: String?
    var jobTitle: String?
    var birthday: Date?
    var emailAddresses: [contactEmailAddress]?
    var phoneNumbers: [contactPhoneNumber]?
}

struct contactEmailAddress: Codable {
    let tag: String
    let value: String
}

struct contactPhoneNumber: Codable {
    let tag: String
    let value: String
}

struct importContactBulkRequest: Codable {
    let deviceId: String?
    let contacts: [importContact]
}

struct createStoryRequest: Codable {
    let input: String
    let location: Location?
    let sessionId: Int64?
    let inChat: Bool?
}

struct createStoryResponse: Codable {
    let id: Int64
    let content: String
    let sessionId: Int64?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.content = try container.decode(String.self, forKey: .content)
        self.sessionId = try container.decodeIfPresent(Int64.self, forKey: .sessionId)
    }
}

struct wordEntity: Hashable, Codable {
    var name: String?
    var type: wordEntityType?
    var externalId: Int64?
}

enum wordEntityType: String, Codable {
    case person = "person"
    case place = "place"
    case organization = "organization"
}

struct Story: Codable, Hashable, Identifiable {
    let id: Int64
    var content: String
    let userAccountId: Int64
    let createdTime: Date
    let lastModifiedTime: Date
    
    func contentWithShareText() -> String {
        return self.content + ConfigModel.buildSharedByText()
    }
}

struct shareStoryRequest: Codable {
    let id: Int64?
    let storyId: Int64?
    let targetUserId: Int64?
    let notificationId: String?
}

struct listStoriesResponse: Codable {
    let storyList: [Story]
    let shareStoryRequests: [shareStoryRequest]
}

struct searchStoriesRequest: Codable {
    let input: String
    let sessionId: Int64?
}

struct storyWithEntities: Codable, Hashable {
    let story: Story?
    let entityList: [wordEntity]?
    let location: Location?
    
    var id: Int64 {
        return story?.id ?? -1
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: storyWithEntities, rhs: storyWithEntities) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(story: Story?, entityList: [wordEntity]?, location: Location?) {
        self.story = story
        self.entityList = entityList
        self.location = location
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.story = try container.decodeIfPresent(Story.self, forKey: CodingKeys.story)
        self.entityList = try container.decodeIfPresent([wordEntity].self, forKey: CodingKeys.entityList)
        self.location = try container.decodeIfPresent(Location.self, forKey: CodingKeys.location)
    }
}

struct searchStoriesResponse: Codable {
    let storyList: [storyWithEntities]
    let sessionId: Int64?
}

struct editStoryRequest: Codable {
    let storyId: Int64
    let content: String
}

struct deleteStoryRequest: Codable {
    let id: Int64
}

struct FindStroyRequest: Codable {
    let StoryID: Int64
}

struct questionDetailsRequest: Codable {
    let questionId: Int64
}

struct questionDetailsResponse: Codable, Hashable, Equatable {
    let id = UUID()
    let question: Question?
    let feedback: [questionFeedback]?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.question = try container.decodeIfPresent(Question.self, forKey: .question)
        self.feedback = try container.decodeIfPresent([questionFeedback].self, forKey: .feedback)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: questionDetailsResponse, rhs: questionDetailsResponse) -> Bool {
        return lhs.id == rhs.id
    }
}

struct questionFeedback: Codable {
    let id: Int64
    let questionId: Int64
    let feedback: String
    let createdTime: Date
}

struct basicContactWithStoryCount: Codable, Identifiable, Hashable {
    var id: Int64 {
        return contactId
    }
    
    let contactId: Int64
    let contactName: String
    let storyCount: Int64
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.contactId = try container.decode(Int64.self, forKey: .contactId)
        self.contactName = try container.decode(String.self, forKey: .contactName)
        self.storyCount = try container.decode(Int64.self, forKey: .storyCount)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct listContactsResponse: Codable {
    let contactsList: [basicContactWithStoryCount]
}

struct linkStoryEntityToContactRequest: Codable {
    let storyId: Int64?
    let entityName: String?
    let contactId: Int64?
}

struct linkQuestionEntityToContactRequest: Codable {
    let questionId: Int64?
    let entityName: String?
    let contactId: Int64?
}

struct email: Codable {
    let tag: String?
    let value: String?
}

struct phone: Codable {
    let tag: String?
    let value: String?
}

struct contactDetails: Codable {
    let firstName: String?
    let middleName: String?
    let lastName: String?
    let nickname: String?
    let organizationName: String?
    let jobTitle: String?
    let birthday: Date?
    let emailAddresses: [email]?
    let phoneNumbers: [phone]?
}

struct listContactSuggestedStoriesResponse: Codable {
    let storyList: [storyWithEntities]?
}

struct contactDetailsResponse: Codable {
    let contact: Contact?
    let details: contactDetails?
    let storyList: [storyWithEntities]?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.contact = try container.decodeIfPresent(Contact.self, forKey: .contact)
        self.details = try container.decodeIfPresent(contactDetails.self, forKey: .details)
        self.storyList = try container.decodeIfPresent([storyWithEntities].self, forKey: .storyList)
    }
}

struct Contact: Codable, Hashable {
    let id: Int64?
    let name: String?
    let externalId: String?
    let userAccountId: Int64?
    let storyId: Int64?
    let dunbarUserId: Int64?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        self.userAccountId = try container.decodeIfPresent(Int64.self, forKey: .userAccountId)
        self.storyId = try container.decodeIfPresent(Int64.self, forKey: .storyId)
        self.dunbarUserId = try container.decodeIfPresent(Int64.self, forKey: .dunbarUserId)
    }
}

struct contactDetailsRequest: Codable {
    let contactId: Int64
}

struct listContactSuggestedStoriesRequest: Codable {
    let contactId: Int64
    let similarityThreshold: Double
}

struct createContactRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let alias: String?
}

struct CreateEntityContactRequest: Codable {
    let contact: createContactRequest
    let entity: createContactEntityRequest
}

struct createContactEntityRequest: Codable {
    let entityName: String?
    let contextType: String?
    let externalId: Int64?
}

struct deleteSessionRequest: Codable {
    let sessionId: Int64?
}

struct submitQuestionFeedbackRequest: Codable {
    let questionId: Int64
    let feedback: String
    let isPositive: Bool
    let isHarmful: Bool
    let notTrue: Bool
    let notHelpful: Bool
}

struct prepareStoriesPageResponse: Codable {
    let storyList: [storyWithEntities]
}

struct Location: Codable {
    let lat: Float64
    let lon: Float64
    let geocode: String?
    
    init(lat: Float64, lon: Float64, geocode: String?) {
        self.lat = lat
        self.lon = lon
        self.geocode = geocode
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lat = try container.decode(Float64.self, forKey: .lat)
        self.lon = try container.decode(Float64.self, forKey: .lon)
        self.geocode = try container.decodeIfPresent(String.self, forKey: .geocode)
    }
}


struct ListSessionInteractionsRequest: Codable {
    let sessionId: Int64?
}

struct ListSessionInteractionsData: Codable {
    let sessionId: Int64
    let storyList: [storyWithEntities]
}

struct Interaction: Decodable {
    let id: Int64
    let sessionId: Int64
    let input: String
    let output: InteractionOutput?
    let type: CNNModelResultTypes?
    let createdTime: Date
    
    enum CodingKeys: String, CodingKey {
        case id, sessionId, input, output, type, createdTime
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.sessionId = try container.decode(Int64.self, forKey: .sessionId)
        self.input = try container.decode(String.self, forKey: .input)
        self.type = try container.decodeIfPresent(CNNModelResultTypes.self, forKey: .type)
        self.createdTime = try container.decode(Date.self, forKey: .createdTime)
        
        switch self.type {
        case .addStory:
            self.output = nil
        case .askQuestion, .searchYourContacts, .unknown:
            let payload = try container.decode(askWithStreamChunkResponse.self, forKey: .output)
            self.output = QuestionInteractionOutput.init(data: payload)
        case .searchYourStories:
            let payload = try container.decode(ListSessionInteractionsData.self, forKey: .output)
            self.output = ListStoriesInteractionOutput.init(data: storyListResponseData(storyList: payload.storyList, prompt: self.input))
        case .none:
            self.output = nil
        }
        
        
    }
}

protocol InteractionOutput {
    var type: CNNModelResultTypes? {get}
}

struct QuestionInteractionOutput: InteractionOutput {
    let type: CNNModelResultTypes? = .askQuestion
    let data: askWithStreamChunkResponse
}

struct ListStoriesInteractionOutput: InteractionOutput {
    let type: CNNModelResultTypes? = .searchYourStories
    let data: storyListResponseData
}

struct ListSessionInteractionsResponse: Decodable {
    let session: Session
    let interactionList: [Interaction]
}

struct EnableCalendarSyncRequest: Codable {
    let authorizationCode: String
    let email: String
}

struct DisableCalendarSyncRequest: Codable {
    let email: String
}

struct CalendarSyncSettingsItem: Codable {
    let email: String
    let createdTime: Date
}

struct PrepareSettingsResponse: Codable {
    let calendarSync: [CalendarSyncSettingsItem]
}

struct RenameSessionRequest: Codable {
    let sessionId: Int64
    let title: String
}


//MARK: - Email Sync Models

// Email Sync Payload
struct EmailSyncPayload: Codable {
    let email : String
}
struct EmailSyncEnablePayload: Codable {
    let email : String
    let authorizationCode : String
}

// Email sync Responses
struct EmailSyncSuccessResponse: Codable {
    let emailSync: EmailSync
}

struct EmailSync: Codable {
    let status: String
    let error: Bool
    let message: String
    let expiresIn: Int?
    let expiresAt: String?
    let hasRefresh: Bool?
    let enabled: Bool?
    let email: String?
    let historyId: Int?
    let expiration: Int?
    let created: String?
    let updated: String?
}
