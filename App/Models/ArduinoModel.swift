//
//  ArduinoModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 7/31/22.
//

import Foundation

struct ArduinoStatus: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    let lastExternalReset, lastUpload: Int
    let onlineSince: OnlineSince
    let resetting, wifiRssi, wifiStatus: Int
    let esp32Resetting: Int

    enum CodingKeys: String, CodingKey {
        case lastExternalReset = "Last External Reset"
        case lastUpload = "Last Upload"
        case onlineSince = "Online Since"
        case resetting = "Resetting"
        case wifiRssi = "Wi-Fi RSSI"
        case wifiStatus = "Wi-Fi Status"
        case esp32Resetting = "ESP32 Resetting"
    }
}

struct OnlineSince: Codable, Hashable {
    let latest: String
    let timeBeforeThat: String
    let totalRuntimeOfLastPowerCycle: Int
    
    enum CodingKeys: String, CodingKey {
        case latest = "Latest"
        case timeBeforeThat = "Time Before That"
        case totalRuntimeOfLastPowerCycle = "Total runtime of last power cycle (minutes)"
    }
}
