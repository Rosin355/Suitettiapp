import UIKit
import UserNotifications

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NSLog("[APNs] ✓ registration succeeded — token prefix: %@…", String(token.prefix(8)))
        Task {
            await PushTokenRegistrationService.shared.register(deviceToken: token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NSLog("[APNs] ✗ registration failed — %@", error.localizedDescription)
    }
}

// MARK: - UNUserNotificationCenterDelegate

final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()
    private override init() { super.init() }

    // Show banner + sound when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        let isRemote = notification.request.trigger is UNPushNotificationTrigger
        NSLog("[APNs] 📲 foreground notification — id: %@ remote: %d", id, isRemote ? 1 : 0)
        handler([.banner, .sound])
    }

    // Parse userInfo and route when user taps notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let isRemote = response.notification.request.trigger is UNPushNotificationTrigger
        NSLog("[APNs] 👆 notification tapped — remote: %d userInfo keys: %@", isRemote ? 1 : 0, Array(userInfo.keys))
        if let link = NotificationDeepLink(userInfo: userInfo) {
            Task { @MainActor in
                AppDeepLinkRouter.shared.handle(link)
            }
        }
        handler()
    }
}
