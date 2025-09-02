//

import Foundation

enum AuthErrors: Error {
    case InvalidToken, RefreshTokenMissing, UnableToObtainToken
    case EmptyPhoneNumber, EmptyCode, EmptyNameOrEmail
}

@Observable
class AuthModel {
    static let shared = AuthModel()
    
    private var authToken: String? = nil
    private var refreshToken: String? = nil
    private var tokenExpirationDate: Date? = nil
    private let userDefaults = ConfigModel.userDefaults()
    private let refreshTokenKey = ConfigModel.suiteName + ".refreshToken"
    
    public internal(set) var isLoggedIn: Bool = false
    public internal(set) var working = true
    public internal(set) var currentUserData: userData? = nil
    
    init(){
        Task{
            await self.initializeAuth()
        }
    }
    
    func logout() {
        Task { @MainActor in
            self.authToken = nil
            self.refreshToken = nil
            self.tokenExpirationDate = nil
            self.isLoggedIn = false
            self.currentUserData = nil
            self.deleteRefreshToken()
            
            NavigationModel.shared.reset()
            NetworkViewModel.shared.reset()
            HomeModel.shared.reset()
            ConfigModel.reset()
            Task {
                await EventsModel.shared.logout()
                await ContactsModel.shared.reset()

            }
        }
    }
    
    func initializeAuth() async {
        do {
            let authSuccesful = try await self.useRefreshToken()
            if authSuccesful {
                await MainActor.run{
                    self.handlePermissions()
                    self.isLoggedIn = true
                }
            } else {
                self.isLoggedIn = false
            }
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("initializeAuth: \(err)")
                await ToastsModel.shared.notifyError(context: "AuthModel.initializeAuth()", error: err)
            }
        }
        
        await MainActor.run{
            self.working = false
        }
    }
    
    func setAuthToken(_ token: String) throws {
        do {
            self.authToken = token
            let parts = token.split(separator: ".")
            let pay = parts[1]
            var string = String(pay)
            switch (string.utf8.count % 4) {
                case 2:
                    string += "=="
                case 3:
                    string += "="
                default:
                    break
            }
            let bytes = Data(base64Encoded: string, options: [.ignoreUnknownCharacters])
            if bytes == nil {
                throw AuthErrors.InvalidToken
            }
            let tokenPayload = try JSONDecoder.apiDecoder.decode(tokenPayload.self, from: bytes!)
            self.tokenExpirationDate = tokenPayload.creationTime.addingTimeInterval(Double(tokenPayload.minutesTimeout * 60))
        } catch let error {
            AppLogs.defaultLogger.error("setAuthToken: \(error)")
            throw error
        }
    }
    
    func getAuthToken() async throws -> String {
        if self.tokenExpirationDate != nil {
            if Date.now > self.tokenExpirationDate! {
                if self.refreshToken != nil {
                    let token = await redeemRefreshToken()
                    if token != nil {
                        return token!
                    }
                    
                } else {
                    throw AuthErrors.RefreshTokenMissing
                }
            } else {
                return self.authToken!
            }
        } else {
            if self.getRefreshToken() != nil {
                let token = await redeemRefreshToken()
                if token != nil {
                    return token!
                }
            }
        }
        
        throw AuthErrors.UnableToObtainToken
    }
    
    func redeemRefreshToken() async -> String? {
        do {
            let authSuccesful = try await self.useRefreshToken()
            if authSuccesful {
                return self.authToken!
            } else {
                self.logout()
                return nil
            }
        } catch {
            AppLogs.defaultLogger.info("redeemRefreshToken: refresh token failed, logging user out")
            self.logout()
            return nil
        }
    }
    
    func setRefreshToken(_ token: String) {
        self.refreshToken = token
        self.userDefaults.setValue(token, forKey: refreshTokenKey)
    }
    
    func getRefreshToken() -> String? {
        if refreshToken != nil {
            return refreshToken
        }
        
        let stored = self.userDefaults.string(forKey: refreshTokenKey)
        if stored != nil {
            return stored
        }
        
        return nil
    }
    
    func deleteRefreshToken() {
        self.userDefaults.removeObject(forKey: refreshTokenKey)
    }
    
    func useRefreshToken() async throws -> Bool {
        let token = self.getRefreshToken()
        if token == nil {
            return false
        }
        
        let result = try await ApiModel.shared.refreshToken(request: refreshTokenRequest(refreshToken: token!))
        await EventsModel.shared.identifyUser(with: result)
        try self.setAuthToken(result.token)
        print("userAuthToken = \(result.token)")
        self.setRefreshToken(result.refreshToken)
        await MainActor.run{
            self.currentUserData = result.userData
        }
        
        return true
    }
    
    func requestPhoneCode(_ number: String) async throws {
        guard !number.isEmpty else {
            throw AuthErrors.EmptyPhoneNumber
        }
        
        try await ApiModel.shared.phoneNumberLogin(number)
    }
    
    func verifyCode(number: String, code: String) async throws {
        guard !code.isEmpty else {
            throw AuthErrors.EmptyCode
        }
        
        let response = try await ApiModel.shared.verifyCode(request: verifyCodeRequest(phoneNumber: number, code: code))
        await EventsModel.shared.identifyUser(with: response)
        try self.setAuthToken(response.token)
        self.setRefreshToken(response.refreshToken)
        self.currentUserData = response.userData
        self.handlePermissions()
        self.isLoggedIn = true
    }
    
    func saveUserData(first: String, last: String, email: String) async throws {
        guard !first.isEmpty && !last.isEmpty && !email.isEmpty else {
            throw AuthErrors.EmptyNameOrEmail
        }
        
        let payload = userData(firstName: first, lastName: last, email: email)
        try await ApiModel.shared.updateUserData(request: payload)
        
        EventsModel.shared.track(UserDataCreated())
        self.currentUserData = payload
        self.isLoggedIn = true
    }
    
    func handlePermissions() {
        
        
        
        if self.currentUserData == nil {
            HomeModel.shared.enqueuePermissionRequest(homePermissionStates.userData)
        }
        if LocationModel.shared.shouldRequestPermission {
            HomeModel.shared.enqueuePermissionRequest(homePermissionStates.location)
        }
        
        let externalSync = ConfigModel.shared.getExternalSync()
        
        if let sync = externalSync {
            
            if (sync.calendarSyncID == nil || sync.emailSyncID == nil), (sync.skipOnboarding == nil || sync.skipOnboarding == false) {
                HomeModel.shared.enqueuePermissionRequest(homePermissionStates.google)
            } else {
                print("sync skipped")
            }
            
        } else {
            
            let semaphore = DispatchSemaphore(value: 0)

            Task {
                
                do {
                    
                    let result1 = try await ApiModel.shared.prepareSettings()
                    if !result1.calendarSync.isEmpty {
                        ConfigModel.shared.updateExternalSync(calendarSyncID: result1.calendarSync.first?.email)
                    }
                    
                } catch let err {
                    if case ApiErrors.RequestTimeout = err {
                        // Handle the timeout error
                        DispatchQueue.main.async {
                            ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                        }
                    } else {
                        AppLogs.defaultLogger.error("initializeAuth: \(err)")
                        DispatchQueue.main.async {
                            ToastsModel.shared.notifyError(message: "Unable to get calendar sync status.")
                        }
                    }
                }
                semaphore.signal()
                
            }
            semaphore.wait()

            
            Task {
                
                do {
                    let result = try await ApiModel.shared.getEmailSyncStatus()
                    if result.emailSync.error == false, let enabled = result.emailSync.enabled, enabled == true {
                        ConfigModel.shared.updateExternalSync(emailSyncID: result.emailSync.email)
                    }
                } catch let err {
                    if case ApiErrors.RequestTimeout = err {
                        // Handle the timeout error
                        DispatchQueue.main.async {
                            ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                        }
                    } else {
                        AppLogs.defaultLogger.error("initializeAuth: \(err)")
                        DispatchQueue.main.async {
                            ToastsModel.shared.notifyError(message: "Unable to get email sync status.")
                        }
                    }
                }
                semaphore.signal()
                
            }
            semaphore.wait()
            
            let externalSync = ConfigModel.shared.getExternalSync()
            if externalSync == nil || (externalSync?.calendarSyncID == nil || externalSync?.emailSyncID == nil) {
                HomeModel.shared.enqueuePermissionRequest(homePermissionStates.google)
            }
            if externalSync?.calendarSyncID != nil, externalSync?.emailSyncID != nil {
                ConfigModel.shared.updateExternalSync(skipOnboarding: true)
            }
        }
        
        let lastContactSync = ConfigModel.shared.findLastContactInteractionDate()
        if lastContactSync == nil {
            HomeModel.shared.enqueuePermissionRequest(homePermissionStates.contacts)
        } else {
            if Date.now.timeIntervalSince(lastContactSync!) > (604800 * 4) {
                HomeModel.shared.enqueuePermissionRequest(homePermissionStates.contacts)
            }
        }
        
        HomeModel.shared.setNextEnqueuedPermission()
    }
    
}

fileprivate struct tokenPayload: Codable {
    let userId: Int64
    let minutesTimeout: Int
    let creationTime: Date
}
