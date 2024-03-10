//
//  FirebaseArduinoControl.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 7/31/22.
//

import Foundation
import Firebase
import Combine
import SwiftUI
import FirebaseSharedSwift

class FirebaseArduinoControl: ObservableObject {
    ///
    @Published var solenoidSignalCode: String = ""
    @Published var solenoidPowerState: Bool = false
    @Published var resetStateBoolTest: Bool = false
    ///
    @Published var arduinoStatus = [ArduinoStatus]()
    @Published var resetCurrentlyInProgress: Int = 0 // maybe should change to bool
    @Published var resetStateBool: Bool = false
    
    let firebaseParentPathName: String = "Arduino Status"
    let childPathResetting: String = "Arduino Status/Resetting"
    let childPathESP32Resetting: String = "Arduino Status/ESP32 Resetting"
    let childPathWifiRssi: String = "Arduino Status/Wi-Fi RSSI"
    let childPathWifiStatus: String = "Arduino Status/Wi-Fi Status"
            
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    func getArduinoResetState() -> Int {
        let ref = Database.database().reference()
        ref.child(childPathResetting).getData(completion:  { error, snapshot in
          guard error == nil else {
            print(error!.localizedDescription)
            return;
          }
          let resetCurrentlyInProgress = snapshot.value as? Int ?? -1
            print("Current Arduino Reset State: \(resetCurrentlyInProgress)")
            if resetCurrentlyInProgress == 1 {
                self.resetCurrentlyInProgress = 1
                print("Current Arduino Reset State: \(self.resetCurrentlyInProgress)")
            }
            else {
                self.resetCurrentlyInProgress = 0
                print("Current Arduino Reset State: \(self.resetCurrentlyInProgress)")
            }
        })
        return self.resetCurrentlyInProgress
    }
    
    func getArduinoResetStateBool() -> Bool {
        let ref = Database.database().reference()
        ref.child(childPathResetting).getData(completion:  { error, snapshot in
          guard error == nil else {
            print(error!.localizedDescription)
            return;
          }
          let resetCurrentlyInProgress = snapshot.value as? Int ?? -1
            print("Current Arduino Reset State: \(resetCurrentlyInProgress)")
            if resetCurrentlyInProgress == 0 {
                self.resetStateBool = false
                print("Current Arduino Reset State: \(self.resetStateBool)")
            }
            else if resetCurrentlyInProgress == 1  {
                self.resetStateBool = true
                print("Current Arduino Reset State: \(self.resetStateBool)")
            } else {
                self.resetStateBool = false
                print("Current Arduino Reset State Not 1 or 0: \(resetCurrentlyInProgress)")
            }
        })
        return self.resetStateBool
    }
    
    func triggerArduinoReset() {
        let ref = Database.database().reference()
        ref.child(childPathResetting).setValue(1) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Error relaying Arduino reset code to Firebase: \(error).")
          } else {
            print("Arduino reset code successfully uploaded to Firebase!")
            print("Arduino is now resetting...")
          }
        }
        ref.child(childPathWifiStatus).setValue(6) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Error relaying Arduino Wi-Fi status code to Firebase: \(error).")
          } else {
            print("Arduino Wi-Fi status code (\(6)) successfully uploaded to Firebase!")
          }
        }
        ref.child(childPathWifiRssi).setValue(-1) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Error relaying Arduino Wi-Fi RSSI to Firebase: \(error).")
          } else {
            print("Arduino Wi-Fi RSSI (\(-1)) successfully uploaded to Firebase!")
          }
        }
    }
    
    func triggerESP32Reset() {
        let ref = Database.database().reference()
        ref.child(childPathESP32Resetting).setValue(1) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Error relaying ESP32 reset code to Firebase: \(error).")
          } else {
            print("ESP32 reset code successfully uploaded to Firebase!")
            print("ESP32 is now resetting...")
          }
        }
    }
    
    func getArduinoStatus() {
        let refArduinoStatus = Database.database().reference().child(firebaseParentPathName)
        databaseHandle = refArduinoStatus.observe(.value, with: { (snapshot) in
                
            guard let value = snapshot.value as? [String: Any] else { return }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value)
                    let decodedArduinoStatus = try JSONDecoder().decode(ArduinoStatus.self, from: jsonData)
                    self.arduinoStatus = [ArduinoStatus(lastExternalReset: decodedArduinoStatus.lastExternalReset, lastUpload: decodedArduinoStatus.lastUpload, onlineSince: decodedArduinoStatus.onlineSince, resetting: decodedArduinoStatus.resetting, wifiRssi: decodedArduinoStatus.wifiRssi, wifiStatus: decodedArduinoStatus.wifiStatus, esp32Resetting: decodedArduinoStatus.esp32Resetting)]
                } catch let error {
                    print("Error json parsing \(error)")
                }
        }) // databaseHandle
    }
}
