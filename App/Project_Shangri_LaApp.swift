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
    
    @StateObject var userSettings = UserSettings() // testing
    @StateObject private var fvm = FirebaseDataService()
    @State private var showLaunchView: Bool = true
    
    init() {
        FirebaseApp.configure()
//        Database.database().isPersistenceEnabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                FirebaseHomeView()
                    .environmentObject(userSettings) // testing
                ZStack {
                    if showLaunchView {
                        LaunchView(showLaunchView: $showLaunchView)
                    }
                } //ZStack
                .environmentObject(fvm)
            }
        } //WindowGroup
    } //Scene
} //struct
