//
//  UserSettings.swift
//  Project-Shangri-La (iOS)
//
//  Created by Nick Doolittle on 5/16/23.
//

import SwiftUI
import Combine

// TODO: (03/10/2023) - This was commented out because it was causing a build error.
// Need to figure out how to reintegrate this into the project.

class UserSettings: ObservableObject {
//    @Published var defaultCamera: IPCamera {
//        didSet {
//            UserDefaults.standard.set(defaultCamera.rawValue, forKey: "defaultCamera")
//        }
//    }
    
    @Published var defaultPlotInterval: String {
        didSet {
            UserDefaults.standard.set(defaultPlotInterval, forKey: "defaultPlotInterval")
        }
    }


    init() {
//        if let defaultCamera = UserDefaults.standard.string(forKey: "defaultCamera") {
//            self.defaultCamera = IPCamera(rawValue: defaultCamera) ?? .cam1
//        } else {
//            self.defaultCamera = .cam1
//        }

        if let defaultPlotInterval = UserDefaults.standard.string(forKey: "defaultPlotInterval") {
            self.defaultPlotInterval = defaultPlotInterval
        } else {
            self.defaultPlotInterval = "1D"
        }
    }
}
