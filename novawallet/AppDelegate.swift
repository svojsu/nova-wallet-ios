import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    var isUnitTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UNITTEST")
    }

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        guard !isUnitTesting else { return true }

        let rootWindow = NovaWindow()
        window = rootWindow
        
        // the requirement is to set the delegate before living didFinishLaunching
        setupPushNotificationsDelegate()

        let presenter = RootPresenterFactory.createPresenter(with: rootWindow)
        presenter.loadOnLaunch()

        rootWindow.makeKeyAndVisible()
        return true
    }
    
    func setupPushNotificationsDelegate() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
    }

    func application(
        _: UIApplication,
        open url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        URLHandlingService.shared.handle(url: url)
    }

    func application(_: UIApplication, supportedInterfaceOrientationsFor _: UIWindow?) -> UIInterfaceOrientationMask {
        DeviceOrientationManager.shared.enabledOrientations
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Logger.shared.debug("Did receive APNS push token")

        PushNotificationsServiceFacade.shared.updateAPNS(token: deviceToken)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.shared.error("Failed to register push notifications: \(error)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        PushNotificationHandlingService.shared.handle(
            userInfo: userInfo
        ) { success in
            if success {
                Logger.shared.debug("Notification handled: \(userInfo)")
            } else {
                Logger.shared.error("Notification handling failed: \(userInfo)")
            }
            
            completionHandler()
        }
    }
}
