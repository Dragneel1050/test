//

import Foundation

enum ApiErrors: Error {
    case MalformedUrl
    case UnsuccesfulStatusCode
    case RequestTimeout
    
    var message: String {
        switch self {
            case .MalformedUrl: return "Url is malformed"
            case .UnsuccesfulStatusCode: return "Unsuccesful status code"
            case .RequestTimeout: return "Request timed out. Please check your connection and try again."
        }
    }
}

@globalActor
actor ApiModel {
    static let shared = ApiModel()
    
//    private let baseUrl = "https://d1bdqkgxibyyft.cloudfront.net"
    private let baseUrl = "https://d2j8ymo8s5yyn1.cloudfront.net"
    private let qaEnvForEmailSyncBaseUrl = "https://qa-email.corbo.app:9443/api/emailSync/"
    
    
    private func newRequest(urlString: String, payload: Data?, headers: [String:String]) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw ApiErrors.MalformedUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = payload
        
        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        return request
    }
    
    private func apiCall<T>(_ type: T.Type, urlString: String, payload: Encodable?, useAuth: Bool = true, extraHeaders: [String:String]? = nil, timeout: TimeInterval = 20) async throws -> T where T: Decodable {

        let encodedPayload: Data? = try {
            if let payload = payload {
                if payload is Data {
                    return (payload as! Data)
                } else {
                    return try JSONEncoder.apiEncoder.encode(payload)
                }
            }
            return nil
        }()
        
        if let data = encodedPayload {
            AppLogs.defaultLogger.trace("apiCall request: \(urlString) \(String(bytes: data, encoding: .utf8) ?? "")")
        }
        
        let headers: [String:String] = try await {
            var result = ["Content-Type" : "application/json"]
            if useAuth {
                result["authToken"] = try await AuthModel.shared.getAuthToken()
            }
            
            if let extraHeaders = extraHeaders {
                result.merge(extraHeaders, uniquingKeysWith: {lhs, rhs in return lhs})
            }
            
            return result
        }()
        
        var request = try newRequest(urlString: urlString, payload: encodedPayload, headers: headers)
        
//        if urlString == "https://qa-api.corbo.app:9443/api/emailSync/prepareSettings" {
//            print("request = \(request)")
//            print("payload = \(payload)")
//            print("encodedPayload = \(encodedPayload)")
//            print("headers = \(headers)")
//            print("extraHeaders = \(extraHeaders)")
//        }
        
        // Set timeout interval for the request
        request.timeoutInterval = timeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode

            AppLogs.defaultLogger.trace("apiCall response: \(urlString) \(String(bytes: data, encoding: .utf8) ?? "")")

            guard code == 200 else {
                if data.count > 0 {
                    AppLogs.defaultLogger.error("apiCall: Error response received from \(request.url?.absoluteString ?? "missing url"): \(String(bytes: data, encoding: .utf8)!)")
                    if let parsedError = try? JSONDecoder.apiDecoder.decode(errorMessage.self, from: data) {
                        throw parsedError
                    } else {
                        throw errorMessage(errorMessage: "apiCall: Error response received from \(request.url?.absoluteString ?? "missing url"): \(String(bytes: data, encoding: .utf8)!)")
                    }
                } else {
                    AppLogs.defaultLogger.error("apiCall: Bad HTTP status code: \(code?.formatted() ?? "missing code")")
                }
                throw ApiErrors.UnsuccesfulStatusCode
            }

            var result: T
            do {
                if type is emptyResponse.Type {
                    result = emptyResponse() as! T
                } else {
                    let serverResponse = try JSONDecoder.apiDecoder.decode(type, from: data)
                    result = serverResponse
                }
            } catch {
                AppLogs.defaultLogger.error("apiCall: Error decoding response \(error.localizedDescription) \(String(data: data, encoding: .utf8) ?? "")")
                throw error
            }

            return result

        } catch {
            if (error as? URLError)?.code == URLError.timedOut {
                
                AppLogs.defaultLogger.error("apiCall: Request timed out")
                throw ApiErrors.RequestTimeout
            } else {
                throw error
            }
        }
    }
    
    func refreshToken(request: refreshTokenRequest) async throws -> verifyCodeResponse {
        return try await self.apiCall(verifyCodeResponse.self, urlString: baseUrl + "/api/core/refreshTokenLogin", payload: request, useAuth: false, extraHeaders: nil)
    }
    
    func phoneNumberLogin(_ number: String) async throws {
        let payload = phoneNumberLoginRequest(phoneNumber: number)
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/phoneNumberLogin", payload: payload, useAuth: false, extraHeaders: nil)
    }
    
    func verifyCode(request: verifyCodeRequest) async throws -> verifyCodeResponse {
        return try await self.apiCall(verifyCodeResponse.self, urlString: baseUrl + "/api/core/verifyCode", payload: request, useAuth: false, extraHeaders: nil)
    }
    
    func updateUserData(request: userData) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/updateUserData", payload: request, extraHeaders: nil)
    }
    
    func transcribeWhisperAudio(data: Data) async throws -> whisperAudioResponse {
        let boundary = UUID().uuidString
        var requestData = Data()
        guard let url = URL(string: baseUrl + "/api/playground/whisperTranscript") else { throw ApiErrors.MalformedUrl }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let headers = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)"
        ]
        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        requestData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        requestData.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.mp4\"\r\n".data(using: .utf8)!)
        requestData.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
        requestData.append(data)
        requestData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let resp = (response as? HTTPURLResponse)
        guard resp?.statusCode == 200 else {
            throw ApiErrors.UnsuccesfulStatusCode
        }
        
        return try JSONDecoder.apiDecoder.decode(whisperAudioResponse.self, from: data)
    }
    
    func askWithStream(
        question: String,
        sessionId: Int64?,
        searchContacts: Bool,
        chunkHandler: @escaping (askWithStreamChunkResponse) async -> Void
    ) async throws {
        let askRequest = askRequest(question: question, sessionId: sessionId, searchContactOnly: searchContacts)
        let payload = try JSONEncoder.apiEncoder.encode(askRequest)
        let extraHeaders = ["authToken" : try await AuthModel.shared.getAuthToken(), "Content-Type" : "application/json"]
        let request = try newRequest(urlString: baseUrl + "/api/core/askWithStream", payload: payload, headers: extraHeaders)
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            AppLogs.defaultLogger.error("askWithStream: Bad HTTP status code \((response as? HTTPURLResponse)?.statusCode.formatted() ?? "missing status code")")
            
            throw ApiErrors.UnsuccesfulStatusCode
        }
        
        
        var iterator = bytes.makeAsyncIterator()
        var buffer = Data()
        var completed = false
        var fullChunk = false
        
        while !completed {
            if let byte = try await iterator.next() {
                buffer.append(contentsOf: [byte])
            } else {
                fullChunk = true
                completed = true
            }
            
            let last2String = String(data: Data(buffer.suffix(2)), encoding: .utf8)
            if last2String?.dropFirst() == "\n" {
                fullChunk = true
            }
            
            if fullChunk {
                do {
                    let chunk = try JSONDecoder.apiDecoder.decode(askWithStreamChunkResponse.self, from: buffer)
                    AppLogs.defaultLogger.trace("\(String(data: buffer, encoding: .utf8) ?? "invalid data")")
                    await chunkHandler(chunk)
                } catch {
                    AppLogs.defaultLogger.error("askWithStream: attempted to decode buffer w invalid json \(String(data: buffer, encoding: .utf8) ?? "invalid utf data")")
                }
                
                buffer.removeAll(keepingCapacity: true)
                fullChunk = false
            }
        }
        
        return
    }
    
    func listSessions() async throws -> listSessionResponse {
        return try await self.apiCall(listSessionResponse.self, urlString: baseUrl + "/api/core/listSessions", payload: nil, extraHeaders: nil)
    }
    
    func listSessionQuestions(sessionId: Int64) async throws -> listSessionQuestionResponse {
        return try await self.apiCall(listSessionQuestionResponse.self, urlString: baseUrl + "/api/core/listSessionQuestions", payload: listSessionQuestionsRequest(sessionId: sessionId), extraHeaders: nil)
    }
    
    func updateApnsDeviceToken(_ token: String) async throws {
        let payload = updateApnsDeviceTokenRequest(token: token)
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/updateApnsDeviceToken", payload: payload, extraHeaders: nil)
    }
    
    func deleteApnsDeviceToken() async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/deleteApnsDeviceToken", payload: nil, extraHeaders: nil)
    }
    
    func importContactBulk(data: Data) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/importContactBulk", payload: data, extraHeaders: nil)
    }
    
    func createStory(content: String, location: Location?, sessionId: Int64?, inChat: Bool?) async throws -> createStoryResponse {
        let request = createStoryRequest(input: content, location: location, sessionId: sessionId, inChat: inChat)
        return try await self.apiCall(createStoryResponse.self, urlString: baseUrl + "/api/core/createStory", payload: request, extraHeaders: nil)
    }
    
    func listStories() async throws -> listStoriesResponse {
        return try await self.apiCall(listStoriesResponse.self, urlString: baseUrl + "/api/core/listStories", payload: nil, extraHeaders: nil)
    }
    
    func searchStories(input: String, sessionId: Int64?) async throws -> searchStoriesResponse {
        return try await self.apiCall(searchStoriesResponse.self, urlString: baseUrl + "/api/core/searchStories", payload: searchStoriesRequest(input: input, sessionId: sessionId), extraHeaders: nil)
    }
    
    func editStory(id: Int64, content: String) async throws -> storyWithEntities {
        return try await self.apiCall(storyWithEntities.self, urlString: baseUrl + "/api/core/editStory", payload: editStoryRequest(storyId: id, content: content), extraHeaders: nil)
    }
    
    func deleteStoryById(id: Int64) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/deleteStory", payload: deleteStoryRequest(id: id), extraHeaders: nil)
    }
    
    func getUpdatedStroy(id: Int64) async throws -> storyWithEntities {
        return try await self.apiCall(storyWithEntities.self, urlString: baseUrl + "/api/core/findStory", payload: FindStroyRequest(StoryID: id), extraHeaders: nil)
    }
    
    func findQuestionDetails(request: questionDetailsRequest) async throws -> questionDetailsResponse {
        return try await self.apiCall(questionDetailsResponse.self, urlString: baseUrl + "/api/core/questionDetails", payload: request, extraHeaders: nil)
    }
    
    func listContacts() async throws -> listContactsResponse {
        return try await self.apiCall(listContactsResponse.self, urlString: baseUrl + "/api/core/listContacts", payload: nil, extraHeaders: nil)
    }
    
    func linkStoryEntityToContact(request: linkStoryEntityToContactRequest) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/linkStoryEntityToContact", payload: request, extraHeaders: nil)
    }
    
    func unlinkStoryEntityToContact(request: linkStoryEntityToContactRequest) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/unlinkStoryEntityToContact", payload: request, extraHeaders: nil)
    }
    
    func linkQuestionEntityToContact(request: linkQuestionEntityToContactRequest) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/linkQuestionEntityToContact", payload: request, extraHeaders: nil)
    }
    
    func unlinkQuestionEntityToContact(request: linkQuestionEntityToContactRequest) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/unlinkQuestionEntityToContact", payload: request, extraHeaders: nil)
    }
    
    func contactDetails(contactId: Int64) async throws -> contactDetailsResponse {
        return try await self.apiCall(contactDetailsResponse.self, urlString: baseUrl + "/api/core/contactDetails", payload: contactDetailsRequest(contactId: contactId), extraHeaders: nil)
    }
    
    func listContactSuggestedStories(contactId: Int64, similarityThreshold: Double) async throws -> listContactSuggestedStoriesResponse {
        return try await self.apiCall(listContactSuggestedStoriesResponse.self, urlString: baseUrl + "/api/core/listContactSuggestedStories", payload: listContactSuggestedStoriesRequest(contactId: contactId, similarityThreshold: similarityThreshold), extraHeaders: nil)
    }
    
    func createContactEntity(request: CreateEntityContactRequest) async throws -> wordEntity {
        try await self.apiCall(wordEntity.self, urlString: baseUrl + "/api/core/createEntityContact", payload: request, extraHeaders: nil)
    }
    
    func submitQuestionFeedback(request: submitQuestionFeedbackRequest) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/submitQuestionFeedback", payload: request, extraHeaders: nil)
    }
    
    func prepareStoriesPage() async throws -> prepareStoriesPageResponse {
        return try await self.apiCall(prepareStoriesPageResponse.self, urlString: baseUrl + "/api/core/prepareStoriesPage", payload: nil)
    }
    
    func listSessionInteractions(id: Int64) async throws -> ListSessionInteractionsResponse {
        return try await self.apiCall(ListSessionInteractionsResponse.self, urlString: baseUrl + "/api/core/listSessionInteractions", payload: ListSessionInteractionsRequest(sessionId: id))
    }
    
    func deleteSession(sessionId: Int64) async throws {
        let _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/deleteSession", payload: deleteSessionRequest(sessionId: sessionId), extraHeaders: nil)
    }
    
    func renameSession(sessionId: Int64, title: String) async throws {
        let _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/core/renameSession", payload: RenameSessionRequest(sessionId: sessionId, title: title))
    }
    
    func enableCalendarSync(authorizationCode: String, email: String) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/calendarSync/enableCalendarSync", payload: EnableCalendarSyncRequest(authorizationCode: authorizationCode, email: email))
    }
    
    func disableCalendarSync(email: String) async throws {
        _ = try await self.apiCall(emptyResponse.self, urlString: baseUrl + "/api/calendarSync/disableCalendarSync", payload: DisableCalendarSyncRequest(email: email))
    }
    
    func prepareSettings() async throws -> PrepareSettingsResponse {
        return try await self.apiCall(PrepareSettingsResponse.self, urlString: baseUrl + "/api/core/prepareSettings", payload: nil)
    }
    
    func getEmailSyncStatus() async throws -> EmailSyncSuccessResponse {
        return try await self.apiCall(EmailSyncSuccessResponse.self, urlString: qaEnvForEmailSyncBaseUrl + "prepareSettings", payload: nil)
    }
    
    func enableEmailSync(authorizationCode: String?, email: String) async throws -> EmailSyncSuccessResponse {
        if let authorizationCode {
            return try await self.apiCall(EmailSyncSuccessResponse.self, urlString: qaEnvForEmailSyncBaseUrl + "enableEmailSync", payload: EmailSyncEnablePayload(email: email, authorizationCode: authorizationCode))
        } else {
            return try await self.apiCall(EmailSyncSuccessResponse.self, urlString: qaEnvForEmailSyncBaseUrl + "enableEmailSync", payload: EmailSyncPayload(email: email))
        }
    }
    
    func disableEmailSyncStatus(email: String) async throws -> EmailSyncSuccessResponse {
        return try await self.apiCall(EmailSyncSuccessResponse.self, urlString: qaEnvForEmailSyncBaseUrl + "disableEmailSync", payload: EmailSyncPayload(email: email))
    }
}
