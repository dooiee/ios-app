//
//  FirebaseViewModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/10/22.
//

import Foundation
import Combine
import Firebase
import FirebaseMessaging
import SwiftUI

class FirebaseViewModel: ObservableObject {
    @Published var pondParameters = [PondParameters]()
    @Published var lastUpdated: Date?
    @Published var notificationSettings: [String: NotificationSetting] = [:]
    @Published var notificationsEnabled: Bool = false
    @Published var hasLoadedSettings: Bool = false // Flag to prevent immediate save
    
    private var initialDataLoaded = false  // Flag to track initial data load
    private let defaultUserId = "defaultUser" // Replace with actual user ID if needed
    private var saveDebounceCancellable: AnyCancellable? // Debounce handler
    private let debounceDelay: TimeInterval = 0.5 // Delay for saving changes
        
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    init() {
        authenticateUser { [weak self] userId in
            guard let self = self, let userId = userId else { return }
            self.ensureNotificationSettingsExist(userId: userId)
        }
    }
    
    func observeFCMTokenRefresh() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTokenRefresh),
            name: .MessagingRegistrationTokenRefreshed,
            object: nil
        )
    }

    @objc func handleTokenRefresh() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching refreshed FCM token: \(error.localizedDescription)")
            } else if let token = token {
                print("Refreshed FCM Token: \(token)")
                self.saveFCMToken(token)
            }
        }
    }
    
    func saveFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated. Cannot save FCM token.")
            return
        }
        
        let ref = Database.database().reference().child("devices").child(token)
        ref.setValue([
            "userId": userId,
            "fcmToken": token
        ]) { error, _ in
            if let error = error {
                print("Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token saved successfully.")
            }
        }
    }
    
    func authenticateUser(completion: @escaping (String?) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            // Return the existing UID
            print("Current user authenticated: \(currentUser.uid)")
            completion(currentUser.uid)
        } else {
            // Sign in anonymously
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("Error signing in anonymously: \(error)")
                    completion(nil)
                } else if let user = authResult?.user {
                    print("Successfully signed in. UID: \(user.uid)")
                    completion(user.uid)
                }
            }
        }
    }

    func ensureNotificationSettingsExist(userId: String) {
        let ref = Database.database().reference().child("users").child(userId).child("notificationSettings")
        ref.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                self.initializeNotificationSettings(userId: userId)
            } else {
                self.fetchNotificationSettings(userId: userId)
            }
        }
    }

    func initializeNotificationSettings(userId: String) {
        let ref = Database.database().reference().child("users").child(userId).child("notificationSettings")
        let initialSettings: [String: Any] = [
            "enabled": false,
            "parameters": [
                "temperature": [
                    "parameter": "Temperature",
                    "aboveThreshold": 75.0,
                    "belowThreshold": 32.0,
                    "notificationFrequency": 300,
                    "isEnabled": true
                ],
                "waterLevel": [
                    "parameter": "Water Level",
                    "aboveThreshold": 10.0,
                    "belowThreshold": 5.0,
                    "notificationFrequency": 600,
                    "isEnabled": true
                ],
                "turbidityValue": [
                    "parameter": "Turbidity",
                    "aboveThreshold": 3000.0,
                    "belowThreshold": 1000.0,
                    "notificationFrequency": 300,
                    "isEnabled": false
                ],
                "totalDissolvedSolids": [
                    "parameter": "TDS",
                    "aboveThreshold": 250.0,
                    "belowThreshold": 50.0,
                    "notificationFrequency": 300,
                    "isEnabled": false
                ],
                "pH": [
                    "parameter": "pH",
                    "aboveThreshold": 8.5,
                    "belowThreshold": 6.3,
                    "notificationFrequency": 600,
                    "isEnabled": false
                ],
            ]
        ]
        ref.setValue(initialSettings) { error, _ in
            if let error = error {
                print("Error initializing notification settings: \(error)")
            } else {
                print("Notification settings initialized successfully.")
                self.fetchNotificationSettings(userId: userId)
            }
        }
    }

    // Fetch the most recent timestamp from Firebase
    func getLastUpdateTimestamp() {
        let ref = Database.database().reference(withPath: "Log/SensorData")
        ref.queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { snapshot in
            if let lastSnapshot = snapshot.children.allObjects.last as? DataSnapshot,
               let data = lastSnapshot.value as? [String: Any],
               let timestamp = data["timestamp"] as? Int {
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
                print("Last updated: \(date)")
                DispatchQueue.main.async {
                    self.lastUpdated = date
                }
            }
        })
    }
    
    func getFirebasePondParameters() {
        let refPondParameters = Database.database().reference().child("CurrentConditions")
        
        databaseHandle = refPondParameters.observe(.value, with: { (snapshot) in
                
            guard let value = snapshot.value as? [String: Any] else { return }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value)
                    let decodedPondParameters = try JSONDecoder().decode(PondParameters.self, from: jsonData)
                    DispatchQueue.main.async {
                        self.pondParameters = [decodedPondParameters]
                        if self.initialDataLoaded {
                            self.lastUpdated = Date() // Update time only after initial data is loaded
                        } else {
                            self.initialDataLoaded = true // Mark initial data as loaded
                        }
                    }
                } catch let error {
                    print("Error json parsing \(error)")
                }
        })
    }
    
    // Fetch notification settings from Firebase
    func fetchNotificationSettings(userId: String) {
        let ref = Database.database().reference().child("users").child(userId).child("notificationSettings")
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let enabled = data["enabled"] as? Bool,
                  let parameters = data["parameters"] as? [String: [String: Any]] else {
                print("Failed to fetch notification settings.")
                return
            }
            
            DispatchQueue.main.async {
                self.notificationsEnabled = enabled
                self.notificationSettings = parameters.compactMapValues { param in
                    guard let notificationFrequency = param["notificationFrequency"] as? Int,
                          let isEnabled = param["isEnabled"] as? Bool else { return nil }
                    return NotificationSetting(
                        parameter: param["parameter"] as? String ?? "",
                        aboveThreshold: param["aboveThreshold"] as? Double,
                        belowThreshold: param["belowThreshold"] as? Double,
                        notificationFrequency: notificationFrequency,
                        isEnabled: isEnabled
                    )
                }
                self.hasLoadedSettings = true // Mark settings as fully loaded
            }
        }
    }
    
    // Save notification settings to Firebase
    func saveNotificationSettings() {
        authenticateUser { userId in
            guard let userId = userId else {
                print("Unable to authenticate user. Cannot save settings.")
                return
            }
            
            let ref = Database.database().reference().child("users").child(userId).child("notificationSettings")
            let settingsToSave: [String: Any] = [
                "enabled": self.notificationsEnabled,
                "parameters": self.notificationSettings.mapValues { setting in
                    [
                        "parameter": setting.parameter,
                        "aboveThreshold": setting.aboveThreshold as Any,
                        "belowThreshold": setting.belowThreshold as Any,
                        "notificationFrequency": setting.notificationFrequency,
                        "isEnabled": setting.isEnabled
                    ]
                }
            ]
            
            ref.setValue(settingsToSave) { error, _ in
                if let error = error {
                    print("Error saving notification settings: \(error)")
                } else {
                    print("Notification settings saved successfully.")
                }
            }
        }
    }
    
    func debounceSaveNotificationSettings() {
        saveDebounceCancellable?.cancel() // Cancel previous debounce if any
        saveDebounceCancellable = Just(())
            .delay(for: .seconds(debounceDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveNotificationSettings()
            }
    }
}
