//
//  Project_Shangri_LaApp.swift
//  Shared
//
//  Created by Nick Doolittle on 2/12/22.
//
import SwiftUI
import Firebase

@main
struct Project_Shangri_LaApp: App {
    
    @StateObject var userSettings = UserSettings()
    @StateObject var fvm = FirebaseViewModel()
    @StateObject var sdm = SensorDataManager()
    @State private var showLaunchView: Bool = true
    
    init() {
        FirebaseApp.configure()
//        Database.database().isPersistenceEnabled = true
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
