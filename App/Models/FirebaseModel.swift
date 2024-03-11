//
//  FirebaseModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/9/22.
//

import Foundation

// MARK: - FirebaseModel
struct FirebaseModel: Identifiable, Codable {
    var id = UUID()//String = UUID().uuidString
    let dataLog: DataLog
    let intervalLog5Min: [String: IntervalLog5Min]
    let mockDataLog: [String: MockDataLog]
    let pondParameters: PondParameters

    enum CodingKeys: String, CodingKey {
        case dataLog = "Data Log"
        case intervalLog5Min = "Interval Log 5min"
        case mockDataLog = "Sensor Data Log"
        case pondParameters = "Pond Parameters"
    }
    init(dataLog: DataLog, intervalLog5Min: [String: IntervalLog5Min], mockDataLog: [String: MockDataLog], pondParameters: PondParameters) {
        self.dataLog = dataLog
        self.intervalLog5Min = intervalLog5Min
        self.mockDataLog = mockDataLog
        self.pondParameters = pondParameters
    }
}

// MARK: - DataLog
struct DataLog: Codable {
    let temperature, totalDissolvedSolids, turbidity, waterLevel: Parameters // changed from Temperature to Parameters

    enum CodingKeys: String, CodingKey {
        case temperature = "Temperature"
        case totalDissolvedSolids = "Total Dissolved Solids"
        case turbidity = "Turbidity"
        case waterLevel = "Water Level"
    }
}

// MARK: - Temperature
struct Parameters: Codable {
    let lastUpdatedAt, value: String

    enum CodingKeys: String, CodingKey {
        case lastUpdatedAt = "Last Updated At"
        case value = "Value"
    }
    init(lastUpdatedAt: String, value: String) {
        self.lastUpdatedAt = lastUpdatedAt
        self.value = value
    }
}

// MARK: - IntervalLog5Min
struct IntervalLog5Min: Codable, Hashable {
    let temperature, timestamp, totalDissolvedSolids, turbidity: String
    let waterLevel: String
    
    enum CodingKeys: String, CodingKey {
        case temperature = "Temperature"
        case timestamp = "Timestamp"
        case totalDissolvedSolids = "Total Dissolved Solids"
        case turbidity = "Turbidity"
        case waterLevel = "Water Level"
    }
}

// MARK: - MockDataLog
struct MockDataLog: Codable, Hashable {
    var temperature: Double
    var timestamp, totalDissolvedSolids, turbidity: Int
    var waterLevel: Double
    let pH: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "Temperature"
        case timestamp = "Timestamp"
        case totalDissolvedSolids = "Total Dissolved Solids"
        case turbidity = "Turbidity"
        case waterLevel = "Water Level"
        case pH = "pH"
    }
    
    init(temperature: Double, timestamp: Int, totalDissolvedSolids: Int, turbidity: Int, waterLevel: Double, pH: Double) {
        
        self.temperature = temperature
        self.timestamp = timestamp
        self.totalDissolvedSolids = totalDissolvedSolids
        self.turbidity = turbidity
        self.waterLevel = waterLevel
        self.pH = pH
    }
}

// MARK: - SensorDataLog (added 5/12/23 as test)
struct SensorDataLog: Codable, Hashable {
    var temperature: Double
    var timestamp, totalDissolvedSolids, turbidity: Int
//    var turbidityVoltage: Double // comment out for now
    var waterLevel: Double
    var pH: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature"
        case timestamp = "timestamp"
        case totalDissolvedSolids = "totalDissolvedSolids"
        case turbidity = "turbidity"
//        case turbidityVoltage = "turbidityVoltage"
        case waterLevel = "waterLevel"
        case pH = "pH"
    }
    
    init(temperature: Double, timestamp: Int, totalDissolvedSolids: Int, turbidity: Int, waterLevel: Double, pH: Double) {

//    init(temperature: Double, timestamp: Int, totalDissolvedSolids: Int, turbidity: Int, turbidityVoltage: Double, waterLevel: Double, pH: Double) {
        
        self.temperature = temperature
        self.timestamp = timestamp
        self.totalDissolvedSolids = totalDissolvedSolids
        self.turbidity = turbidity
//        self.turbidityVoltage = turbidityVoltage
        self.waterLevel = waterLevel
        self.pH = pH
    }
}

// MARK: - PondParameters: Original current working model
struct PondParameters: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    let temperature: Double
    let totalDissolvedSolids, turbidityValue: Int
    let turbidityVoltage, waterLevel: Double
    let pH: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature"
        case totalDissolvedSolids = "totalDissolvedSolids"
        case turbidityValue = "turbidity"
        case turbidityVoltage = "turbidityVoltage"
        case waterLevel = "waterLevel"
        case pH = "pH"
    }
}
