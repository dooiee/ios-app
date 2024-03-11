//
//  FirebaseArduinoStats.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 8/29/22.
//

import Foundation
import Firebase
import Combine
import SwiftUI
import FirebaseSharedSwift

class FirebaseArduinoStatistics: ObservableObject {
    let firebaseParentPathName: String = "Arduino Reset Log"
    let childPathMKRResetCount: String = "Arduino Reset Log/MKR 1010"
    let childPathESPResetCount: String = "Arduino Reset Log/ESP32"
    
    @Published var arduinoStatistics = [ArduinoResetLog]()
    @Published var mkrStatistics = [MKR1010]()
    @Published var espStatistics = [ESP32]()
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    func getStatistics() {
        getMKRStatistics()
        getESPStatistics()
    }
    
    func getMKRStatistics() {
        let refStatistics = Database.database().reference().child(childPathMKRResetCount)
        databaseHandle = refStatistics.observe(.value, with: { (snapshot) in
            guard let value = snapshot.value as? [String: Any] else { return }
            let values = value.map({ ($0.value) })
            self.mkrStatistics = [MKR1010(resetCount: values.count)]
            print("MKR 1010 Statistics - Reset Count: \(values.count)")
        }) // databaseHandle
    }
    func getESPStatistics() {
        let refStatistics = Database.database().reference().child(childPathESPResetCount)
        databaseHandle = refStatistics.observe(.value, with: { (snapshot) in
            guard let value = snapshot.value as? [String: Any] else { return }
            let values = value.map({ ($0.value) })
            self.espStatistics = [ESP32(resetCount: values.count)]
            print("ESP32 Statistics - Reset Count: \(values.count)")
        }) // databaseHandle
    }
    
    //    func getESPResetCount() -> Int {
    //        let ref = Database.database().reference()
    //        ref.child(childPathESPResetCount).observe(.value, with: { (snapshot) in
    //            let espResetCount = snapshot.childrenCount
    //            print("Total number of ESP resets: \(espResetCount)")
    //        })
    //        return self.espResetCount
    //    }
    //
    //    func getMKRResetCount() -> Int {
    //        let ref = Database.database().reference()
    //        ref.child(childPathMKRResetCount).getData(completion:  { error, snapshot in
    //          guard error == nil else {
    //            print(error!.localizedDescription)
    //            return;
    //          }
    //            let mkrResetCount = Int(snapshot.childrenCount)
    //            print("Total number of MKR resets: \(mkrResetCount)")
    //        })
    //        return mkrResetCount
    //    }
    
}
