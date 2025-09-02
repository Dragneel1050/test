//

import NotificationCenter
import SwiftUI

class NotificationsModel {
    static let shared = NotificationsModel()
    @AppStorage("notificationsEnabled", store: ConfigModel.userDefaults()) private var notificationsEnabled = false
    
    func apnsRegistration() {
        guard notificationsEnabled else { return }

        Task{
            do {
                let center = UNUserNotificationCenter.current()
                let enabled = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if enabled {
                    await UIApplication.shared.registerForRemoteNotifications()
                } else {
                    await self.disable()
                }
            } catch {
                AppLogs.defaultLogger.error("apnsRegistration: Unable to enable notifications")
            }
        }
    }
    
    func updateBeApnsDeviceId(deviceToken: Data) {
        guard notificationsEnabled else { return }
        
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task(priority: .utility) {
            do {
                try await ApiModel.shared.updateApnsDeviceToken(token)
                AppLogs.defaultLogger.info("updateApnsDeviceId: \(token)")
            } catch let err {
                AppLogs.defaultLogger.error("updateBeApnsDeviceId: unable to updateApnsDeviceId \(err)")
            }
        }
    }
    
    func handleBackgroundApns(userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard notificationsEnabled else {
            completionHandler(.noData)
            return
        }
        
        guard let payload = self.parseUserInfo(userInfo) else {
            AppLogs.defaultLogger.error("handleBackgroundApns: invalid payload \(userInfo)")
            completionHandler(.failed)
            return
        }
        
        guard let category = payload.category else {
            AppLogs.defaultLogger.error("handleBackgroundApns: invalid payload missing category \(userInfo)")
            completionHandler(.failed)
            return
        }
        
        AppLogs.defaultLogger.info("handleBackgroundApns: notification category \(category)")
        
        /*
        switch category {
            case notificationCategory.storyShared.rawValue:
                Task{
                    await storiesController.loadAllStories()
                    try? await UNUserNotificationCenter.current().setBadgeCount(payload.badge ?? 0)
                    if navigationController.lastScenePhase == .active {
                        StoreActor.shared.displayMessage(text: payload.alert!.body!, bgColor: .white, textColor: .black)
                    }
                    completionHandler(.newData)
                }
            default:
                ("invalid category")
                completionHandler(.failed)
        }
         */
        
        completionHandler(.noData)
    }
    
    func handleAlertApns(response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard notificationsEnabled else {
            completionHandler()
            return
        }
        
        /*
        switch response.notification.request.content.categoryIdentifier {
            case notificationCategory.storyShared.rawValue:
                navigationController.setCurrentTab(.Stories, navigationAction: .sharedStory)
            default:
                ("invalid category")
        }
         */
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
        completionHandler()
    }
    
    func disable() async {
        guard notificationsEnabled else { return }
        
        notificationsEnabled = false
        Task(priority: .utility) {
            do {
                try await ApiModel.shared.deleteApnsDeviceToken()
            } catch let err {
                AppLogs.defaultLogger.error("disable: unable to delete apns device token \(err)")
            }
        }
    }
    
    private func parseUserInfo(_ userInfo: [AnyHashable : Any]) -> notificationPayload? {
        if let aps = userInfo["aps"] {
            do {
                let data =  try JSONSerialization.data(withJSONObject: aps)
                let payload = try JSONDecoder.apiDecoder.decode(notificationPayload.self, from: data)
                
                return payload
            } catch let err {
                AppLogs.defaultLogger.error("parseUserInfo: unable to decode userInfo \(err)")
            }
        }
        
        return nil
    }
}

fileprivate struct alert: Codable {
    let title: String?
    let subtitle: String?
    let body: String?
}

fileprivate struct notificationPayload: Codable {
    let alert: alert?
    let badge: Int?
    let sound: String?
    let category: String?
}

