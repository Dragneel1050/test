//

import SwiftUI

@Observable
class ToastsModel {
    static let shared = ToastsModel()
    
    public var toastState = ToastState()
    
    @MainActor
    func displayMessage(text: String, bgColor: Color = .red, textColor: Color = .white) {
        withAnimation {
            self.toastState.text = text
            self.toastState.backgroundColor = bgColor
            self.toastState.textColor = textColor
        }
    }
    
    @MainActor
    func notifyError(message: String? = nil, context: String? = nil, error: Error? = nil) {
        let errMessage = {
            if message != nil {
                return message!
            } else {
                return "Something went wrong!"
            }
        }()
        
        self.displayMessage(text: errMessage)
        
        EventsModel.shared.track(ErrorShown(errorText: errMessage, context: context, errorDetails: extractErrorMessage(error: error)))
    }
    
    private func extractErrorMessage(error: Error?) -> String? {
        if let error = error{
            if let errMessage = error as? errorMessage {
                return errMessage.errorMessage
            }
            
            return error.localizedDescription
        }
        
        return nil
    }
}
