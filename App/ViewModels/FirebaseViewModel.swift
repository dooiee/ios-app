//
//  GraphViewModel.swift
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
    
    init() {
        getFirebasePondParameters()
    }
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    func getFirebasePondParameters() {
        let refPondParameters = Database.database().reference().child("Pond Parameters")
        
//        databaseHandle = refPondParameters.observe(.childChanged) { (snapshot) in
        databaseHandle = refPondParameters.observe(.value, with: { (snapshot) in
                
            guard let value = snapshot.value as? [String: Any] else { return }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value)
                    let decodedPondParameters = try JSONDecoder().decode(PondParameters.self, from: jsonData)
//                    self.pondParameters.append(decodedPondParameters)
                    self.pondParameters = [PondParameters(temperature: decodedPondParameters.temperature, totalDissolvedSolids: decodedPondParameters.totalDissolvedSolids, turbidityValue: decodedPondParameters.turbidityValue, turbidityVoltage: decodedPondParameters.turbidityVoltage, waterLevel: decodedPondParameters.waterLevel, pH: decodedPondParameters.pH)]
                } catch let error {
                    print("Error json parsing \(error)")
                }
        }) // databaseHandle
    } // func
} // class
