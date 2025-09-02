//
//  CorboApp.swift
//  Corbo
//
//  Created by Agustín Nanni on 23/05/2024.
//

import SwiftUI
import NotificationCenter
import Combine
import AppAuth
import GoogleSignIn

@main
struct CorboApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var toast = ToastsModel.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            Toasts(state: $toast.toastState){
                Splash()
            }
            .onOpenURL { url in
              GIDSignIn.sharedInstance.handle(url)
            }
            .onChange(of: scenePhase, handleScenePhaseChange)
        }
        
    }
    
    func handleScenePhaseChange(_ old: ScenePhase, _ new: ScenePhase) {
        switch new {
        case .background, .inactive:
            if let model = HomeModel.shared.chatViewModel {
                model.doLeave()
            }
        default:
            return
        }
    }
}

enum googleSigninRequestState {
    case working, done, failed
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    var googleSigninStatesProducer = PassthroughSubject<googleSigninRequestState, Never>()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken
                     deviceToken: Data) {
        NotificationsModel.shared.updateBeApnsDeviceId(deviceToken: deviceToken)
    }
    
    func application(
        _ application: UIApplication, 
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationsModel.shared.handleBackgroundApns(userInfo: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationsModel.shared.handleAlertApns(response: response, withCompletionHandler: completionHandler)
        completionHandler()
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        var handled: Bool

        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
          return true
        }
        
        return false
    }
    
    func requestGoogleSigninAuth(scope : GoogleSyncScopeTypes) {
        googleSigninStatesProducer.send(.working)

        GIDSignIn.sharedInstance.signIn(
            withPresenting: getRootViewController(),
            hint: String(localized: "General.Google.Hint"),
            additionalScopes: [GoogleSyncScopeTypes.userinfo.rawValue, scope.rawValue]
        ) { signInResult, error in
            guard error == nil else {
                AppLogs.defaultLogger.error("\(error!.localizedDescription)")
                ToastsModel.shared.notifyError(message: String(localized: "Error.GoogleLogin"), context: "google config", error: error)
                self.googleSigninStatesProducer.send(.failed)
                return
            }
            
            
            guard let result = signInResult else {
                self.googleSigninStatesProducer.send(.failed)
                return
            }
            
            Task{
                do {
                    let code = result.serverAuthCode
                    let email = result.user.profile?.email
                    print("google auth code = \(code)")
                    if [code, email].allSatisfy({ $0 != nil }) {
                        
                        
                        switch scope {
                        case .gmail:
                            
                            let result = await GoogleSyncViewModel.shared.enableGmailSync(authorizationCode: code!, email: email!)
                            
                            if result?.emailSync.error == false, let enabled = result?.emailSync.enabled, enabled == true {
                                ConfigModel.shared.updateExternalSync(emailSyncID: email)
                                self.googleSigninStatesProducer.send(.done)
                            } else {
                                self.googleSigninStatesProducer.send(.failed)
                            }
                            print("enableGmailSync response = \(String(describing: result))")
                            
                        case .calendar:
                            
                            let result = await GoogleSyncViewModel.shared.enableCalendarSync(authorizationCode: code!, email: email!)
                            if result {
                                ConfigModel.shared.updateExternalSync(calendarSyncID: email)
                            }
                            print("enableCalendarSync response = \(result)")
                            self.googleSigninStatesProducer.send(.done)
                            
                        case .userinfo:
                            break
                        }
                        
                    } else {
                        ToastsModel.shared.notifyError(message: String(localized: "Error.GoogleLogin"), context: "google missing data", error: nil)
                        self.googleSigninStatesProducer.send(.failed)
                    }
                    
                } catch let err {
                    ToastsModel.shared.notifyError(message: String(localized: "Error.GoogleLogin"), context: "google login", error: err)
                    self.googleSigninStatesProducer.send(.failed)
                }
            }
        }
    }
    
    private func getRootViewController() -> UIViewController {
           guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
               return . init()
               
           }
           
           guard let root = screen.windows.first?.rootViewController else {
               return .init()
           }
           return root
       }
}
