//
//  MCUStatisticsModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 8/29/22.
//

import Foundation

struct ArduinoStatistics: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    let arduinoResetLog: ArduinoResetLog

    enum CodingKeys: String, CodingKey {
        case arduinoResetLog = "Arduino Reset Log"
    }
}

struct ArduinoResetLog: Codable, Hashable {
    let mkr1010: [String: Data]
    let esp32: [String: Data]
    
    enum CodingKeys: String, CodingKey {
        case mkr1010 = "MKR 1010"
        case esp32 = "ESP32"
    }
}

struct MKR1010: Codable, Hashable {
    let resetCount: Int
    //TODO: add wi-fi disconnects and reliability later
}

struct ESP32: Codable, Hashable {
    let resetCount: Int
    //TODO: add wi-fi disconnects and reliability later
}

