//
//  FirebaseViewModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/10/22.
//

import Foundation
import Combine
import Firebase
import SwiftUI

class FirebaseViewModel: ObservableObject {
    @Published var pondParameters = [PondParameters]()
    @Published var lastUpdated: Date?
    private var initialDataLoaded = false  // Flag to track initial data load
        
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?

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
}
