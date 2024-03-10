//
//  FirebaseUploadData.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 4/2/22.
//

import Foundation
import Firebase
import Combine
import SwiftUI

class FirebaseUploadData: ObservableObject {
    
    @Published var rfSignalCode: [String] = []
    @Published var rfPowerState: Bool = false
            
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    init() {
        self.rfPowerState = getCurrentRFPowerState()
    }
    
    func getCurrentRFPowerState() -> Bool {
        let ref = Database.database().reference()
        ref.child("rfTransmitterCode/Power").getData(completion:  { error, snapshot in
          guard error == nil else {
            print(error!.localizedDescription)
            return;
          }
          let powerCode = snapshot.value as? String ?? "nil"
            print("Current RFPowerState: \(powerCode)")
            self.rfPowerState = powerCode == "111111111111111100000001" ? true : false
        })
        return self.rfPowerState
    }
    
    func uploadRFPowerSignal(rfPowerState: String) {
        let ref = Database.database().reference()
                
        ref.child("rfTransmitterCode/Power").setValue(rfPowerState) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Error uploading Power Signal to Firebase: \(error).")
          } else {
            print("Power Signal successfully uploaded to Firebase!")
          }
        }
    }
    
    func uploadRFColorCode(rfCode: String, color: Color) {
        let ref = Database.database().reference()
                
        ref.child("rfTransmitterCode/Code").setValue(rfCode) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Error uploading Color Code(\(color)) to Firebase: \(error).")
          } else {
            print("Color Code(\(color)) successfully uploaded to Firebase!")
          }
        }
        
    }
    
    func uploadRFColorCodeDecimal(rfCode: Int, color: Color) {
        let ref = Database.database().reference()
                
        ref.child("rfTransmitterCode/Code(Decimal)").setValue(rfCode) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Error uploading Decimal Color Code(\(color)) to Firebase: \(error).")
          } else {
            print("Decimal Color Code(\(color)) successfully uploaded to Firebase!")
          }
        }
        
    }
}
