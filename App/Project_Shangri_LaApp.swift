//
//  Project_Shangri_LaApp.swift
//  Shared
//
//  Created by Nick Doolittle on 2/12/22.
//
import SwiftUI
import Firebase
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        // Firebase setup
//        FirebaseApp.configure()
        
        // Set Messaging delegate
        Messaging.messaging().delegate = self

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Map APNs token to Firebase
        Messaging.messaging().apnsToken = deviceToken
        print("APNs Device Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // Save the FCM token to your backend or Firebase Realtime Database
        if let token = fcmToken {
            FirebaseViewModel().saveFCMToken(token)
        }
    }
}

@main
struct Project_Shangri_LaApp: App {
    
    @StateObject var userSettings = UserSettings()
    @StateObject var fvm = FirebaseViewModel()
    @StateObject var sdm = SensorDataManager()
    @State private var showLaunchView: Bool = true
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseApp.configure()
//        Database.database().isPersistenceEnabled = true
        setupPushNotifications()
    }
    
    private func setupPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notifications authorization: \(error.localizedDescription)")
                return
            }
            print("Push notification authorization granted: \(granted)")
            
            // Set the notification delegate
//            UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        }
        
        // Register with APNs
//        UIApplication.shared.registerForRemoteNotifications()
        
        // Observe FCM token refresh
        fvm.observeFCMTokenRefresh()
        
        // Fetch the initial token
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
            } else if let token = token {
                print("FCM Token: \(token)")
                fvm.saveFCMToken(token)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                FirebaseHomeView()
                    .environmentObject(userSettings)
                    .environmentObject(fvm)
                    .environmentObject(sdm)
                ZStack {
                    if showLaunchView {
                        LaunchView(showLaunchView: $showLaunchView)
                    }
                }
            }
        }
    }
}
