//
//  NotificationSettingsSheet.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 1/4/25.
//

import SwiftUI
import Firebase

struct NotificationSettingsSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var firebaseViewModel: FirebaseViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Display a loader until data is fetched
                if firebaseViewModel.hasLoadedSettings {
                    Toggle(isOn: $firebaseViewModel.notificationsEnabled) {
                        Text("Enable Notifications")
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .onChange(of: firebaseViewModel.notificationsEnabled) { _ in
                        firebaseViewModel.saveNotificationSettings()
                    }
                } else {
                    // Show a loader in place of the toggle while fetching data
                    HStack {
                        ProgressView()
                        Text("Loading Settings...")
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                if firebaseViewModel.notificationsEnabled && firebaseViewModel.hasLoadedSettings {
                    ScrollView {
                        ForEach(Array(firebaseViewModel.notificationSettings.keys).sorted(), id: \.self) { key in
                            if let setting = firebaseViewModel.notificationSettings[key] {
                                NotificationSettingsView(setting: Binding(
                                    get: { firebaseViewModel.notificationSettings[key]! },
                                    set: { firebaseViewModel.notificationSettings[key] = $0 }
                                ))
                                .onChange(of: firebaseViewModel.notificationSettings[key]) { _ in
                                    firebaseViewModel.debounceSaveNotificationSettings()
                                }
                                .padding(.bottom)
                            }
                        }
                    }
                } else if firebaseViewModel.hasLoadedSettings {
                    Text("Notifications are disabled.")
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Notification Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Done")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                firebaseViewModel.authenticateUser { userId in
                    if let userId = userId {
                        firebaseViewModel.fetchNotificationSettings(userId: userId)
                    }
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsSheet()
        .environmentObject(FirebaseViewModel())
}
