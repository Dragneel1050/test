//

import SwiftUI

@Observable
class NetworkViewModel {
    static let shared = NetworkViewModel()
    func reset() {
        self.sessionList = nil
    }
    
    var sessionList: [Session]?
    var canRetry = true
    
    init(listSessionsResponse: listSessionResponse? = nil) {
        self.sessionList = listSessionsResponse?.sessionList
    }
    

    func findListSessionResponse() async {
        self.sessionList = nil
        
        do {
            let result = try await ApiModel.shared.listSessions().sessionList
            await MainActor.run {
                self.sessionList = result
                self.canRetry = true
            }
        }
        catch AuthErrors.UnableToObtainToken {
            AppLogs.defaultLogger.warning("List sessions got cancelled by invalid token!")
            return
        }
        catch let err {
            let error = err as NSError
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                AppLogs.defaultLogger.warning("List sessions got cancelled!")
                return
            }
            self.sessionList = []
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("findListSessionResponse: \(err)")
                await ToastsModel.shared.notifyError(context: "NetworkViewModel.findListSessionResponse()", error: err )
            }
        }
    }
    
    @MainActor
    func openSession(_ session: Session, chatViewOpen: Binding<Bool>) {
        HomeModel.shared.openPreviousSession(session, chatViewOpen: chatViewOpen)
    }
    
    func deleteSession(_ session: Session) async -> Void {
        guard let id = session.id else {
            return
        }
        do {
            try await ApiModel.shared.deleteSession(sessionId: id)
            await MainActor.run {
                self.sessionList = self.sessionList?.filter({ $0.id != id })
            }
        } catch let err {
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("deleteSession: \(err)")
                await ToastsModel.shared.notifyError(context: "NetworkViewModel.deleteSession()", error: err )
            }
        }
    }
}
