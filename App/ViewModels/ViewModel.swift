//
//  SensorData.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 2/13/22.
//

import Combine
import Foundation
import Firebase
import SwiftUI

class ViewModel: ObservableObject {

    @Published var list = [Todo]()
    
    init() {
        list = self.list
        getData()
    }
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    func getData() {
        // MARK: Parsing returned Firebase Data
        let ref = Database.database().reference()
        
        databaseHandle = ref.child("Pond Parameters").observe(.value, with: { (snapshot) in
            
            guard let value = snapshot.value as? [String: Any] else { return }
//            print("Value: \(value)")
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value)
//                    let pondData = try JSONDecoder().decode([String: Todo].self, from: jsonData)
                    let pondDataPrint = try JSONDecoder().decode(Todo.self, from: jsonData)
                    //print(pondDataPrint)
//                    self.list.append(pondDataPrint)
                    self.list = [Todo(temperature: pondDataPrint.temperature, turbidityValue: pondDataPrint.turbidityValue, turbidityVoltage: pondDataPrint.turbidityVoltage, waterLevel: pondDataPrint.waterLevel, totalDissolvedSolids: Int(pondDataPrint.totalDissolvedSolids))]
                    
                    ///*
                    ///print("Temperature: \(pondDataPrint.temperature)\u{00B0}F")
                    ///print("Water Level: \(pondDataPrint.waterLevel) in")
                    ///print("Turbidity: \(pondDataPrint.turbidityValue) NTU")
                    ///print("Total Dissolved Solids: \(pondDataPrint.totalDissolvedSolids) ppm")
                    ///*/

                } catch let error {
                    print("Error json parsing \(error)")
                }
            
        })
        
    } // func
} // class
                    

    

    
    



