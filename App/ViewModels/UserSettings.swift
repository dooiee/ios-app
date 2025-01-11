//
//  UserSettings.swift
//  Project-Shangri-La (iOS)
//
//  Created by Nick Doolittle on 5/16/23.
//

import SwiftUI
import Combine

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @Published var defaultCamera: IPCamera {
        didSet {
            UserDefaults.standard.set(defaultCamera.rawValue, forKey: "defaultCamera")
        }
    }
    
    @Published var defaultPlotInterval: String {
        didSet {
            UserDefaults.standard.set(defaultPlotInterval, forKey: "defaultPlotInterval")
        }
    }
    
    @Published var debugMode: Bool {
        didSet {
            UserDefaults.standard.set(debugMode, forKey: "debugMode")
        }
    }

    init() {
        if let defaultCamera = UserDefaults.standard.string(forKey: "defaultCamera") {
            self.defaultCamera = IPCamera(rawValue: defaultCamera) ?? .cam1
        } else {
            self.defaultCamera = .cam3
        }

        if let defaultPlotInterval = UserDefaults.standard.string(forKey: "defaultPlotInterval") {
            self.defaultPlotInterval = defaultPlotInterval
        } else {
            self.defaultPlotInterval = "1D"
        }
        
        if let debugMode = UserDefaults.standard.value(forKey: "debugMode") as? Bool {
            self.debugMode = debugMode
        } else {
            self.debugMode = false
        }
    }
}
