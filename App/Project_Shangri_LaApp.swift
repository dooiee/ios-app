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
    
    @StateObject private var fdr = FirebaseDataRetreivalForInterval()
    @State private var showLaunchView: Bool = true
    
    init() {
        FirebaseApp.configure()
//        Database.database().isPersistenceEnabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                //MARK: Comment out launch screen animation and main view for now
                FirebaseHomeView()
//                   ZStack {
//                     if showLaunchView {
//                         LaunchView(showLaunchView: $showLaunchView)
//                             .transition(AnyTransition.opacity.animation(.easeIn(duration: 0.5)))
//                     }
            } //ZStack
            .environmentObject(fdr)
        } //WindowGroup
    } //Scene
} //struct
