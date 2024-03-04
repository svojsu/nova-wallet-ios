import Foundation
import UserNotifications
import UIKit
import FirebaseMessaging
import RobinHood
import SoraKeystore
import SoraFoundation

enum PushNotificationsStatus {
    case authorized
    case active
    case denied
    case notDetermined
    case unknown
}

protocol PushNotificationsStatusServiceProtocol: AnyObject, ApplicationServiceProtocol {
    var delegate: PushNotificationsStatusServiceDelegate? { get set }

    var statusObservable: Observable<PushNotificationsStatus> { get }

    func register()
    func deregister()

    func enablePushNotifications()
    func disablePushNotifications()
}

protocol PushNotificationsStatusServiceDelegate: AnyObject {
    func didReceivePushNotifications(token: String)
}

final class PushNotificationsStatusService: NSObject {
    let settingsManager: SettingsManagerProtocol
    let logger: LoggerProtocol
    let statusObservable: Observable<PushNotificationsStatus> = .init(state: .unknown)

    private let notificationCenter = UNUserNotificationCenter.current()
    private let applicationHandler: ApplicationHandlerProtocol

    weak var delegate: PushNotificationsStatusServiceDelegate?

    init(
        settingsManager: SettingsManagerProtocol,
        applicationHandler: ApplicationHandlerProtocol,
        logger: LoggerProtocol
    ) {
        self.settingsManager = settingsManager
        self.applicationHandler = applicationHandler
        self.logger = logger
    }

    private func status(
        completionQueue queue: DispatchQueue?,
        completion: @escaping (PushNotificationsStatus) -> Void
    ) {
        let notificationsEnabled = settingsManager.notificationsEnabled
        notificationCenter.getNotificationSettings { settings in
            dispatchInQueueWhenPossible(queue) {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    if notificationsEnabled {
                        completion(.active)
                    } else {
                        completion(.authorized)
                    }
                case .denied, .ephemeral:
                    completion(.denied)
                case .notDetermined:
                    completion(.notDetermined)
                @unknown default:
                    completion(.notDetermined)
                }
            }
        }
    }

    private func updateStatus() {
        status(completionQueue: nil) { [weak self] newStatus in
            self?.statusObservable.state = newStatus
        }
    }

    private func setupNotificationDelegates() {
        Messaging.messaging().delegate = self
        notificationCenter.delegate = self
    }

    private func clearNotificationDelegates() {
        Messaging.messaging().delegate = nil
        notificationCenter.delegate = nil
    }
}

extension PushNotificationsStatusService: PushNotificationsStatusServiceProtocol {
    func setup() {
        applicationHandler.delegate = self
        updateStatus()
    }

    func throttle() {
        applicationHandler.delegate = nil

        if settingsManager.notificationsEnabled {
            clearNotificationDelegates()
        }
    }

    func register() {
        setupNotificationDelegates()

        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            dispatchInQueueWhenPossible(.main) {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }

                if let error = error {
                    self?.logger.error(error.localizedDescription)
                }

                self?.updateStatus()
            }
        }
    }

    func deregister() {
        Messaging.messaging().deleteToken { [weak self] optError in
            if let error = optError {
                self?.logger.error("FCM token remove failed: \(error)")
            } else {
                self?.logger.error("FCM token removed")
            }

            self?.updateStatus()
        }
    }

    func enablePushNotifications() {
        guard !settingsManager.notificationsEnabled else {
            return
        }

        settingsManager.notificationsEnabled = true

        register()
    }

    func disablePushNotifications() {
        guard settingsManager.notificationsEnabled else {
            return
        }

        settingsManager.notificationsEnabled = false

        deregister()
    }
}

extension PushNotificationsStatusService: MessagingDelegate {
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            delegate?.didReceivePushNotifications(token: fcmToken)
        }
    }
}

extension PushNotificationsStatusService: UNUserNotificationCenterDelegate {
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error(error.localizedDescription)
    }
}

extension PushNotificationsStatusService: ApplicationHandlerDelegate {
    func didReceiveWillEnterForeground(notification _: Notification) {
        updateStatus()
    }
}
