//
//  FirebaseSolenoidControl.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 5/16/22.
//

import Foundation
import Firebase
import Combine
import SwiftUI

class FirebaseSolenoidControl: ObservableObject {
    
    @Published var solenoidSignalCode: String = ""
    @Published var solenoidPowerState: Bool = false
    let firebaseChildPathName: String = "Solenoid Control"
            
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    func getCurrentSolenoidPowerState() -> Bool {
        let ref = Database.database().reference()
        ref.child(firebaseChildPathName).getData(completion:  { error, snapshot in
          guard error == nil else {
            print(error!.localizedDescription)
            return;
          }
          let solenoidPowerCode = snapshot.value as? String ?? "nil"
            print("Current Solenoid Power State: \(solenoidPowerCode)")
            if solenoidPowerCode == "ON" {
                self.solenoidPowerState = true
                print("Current Solenoid Power State: \(self.solenoidPowerState)")
            }
            else {
                self.solenoidPowerState = false
                print("Current Solenoid Power State: \(self.solenoidPowerState)")
            }
//            self.solenoidPowerState = solenoidPowerCode == "111111111111111100000001" ? true : false
        })
        return self.solenoidPowerState
    }
    
    func uploadSolenoidPowerSignal(solenoidPowerState: String) {
        let ref = Database.database().reference()
                
        ref.child(firebaseChildPathName).setValue(solenoidPowerState) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Error uploading Solenoid Power Signal to Firebase: \(error).")
          } else {
            print("Solenoid Power Signal successfully uploaded to Firebase!")
            print("Solenoid Valve is now \(solenoidPowerState)")
          }
        }
    }
}
