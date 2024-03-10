//
//  FirebaseModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/9/22.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? newJSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

// Sample PondData Json //
/*
 SamplePondData JSON response:
 
 {
   "Data Log" : {
     "Temperature" : {
       "Last Updated At" : "1646925104",
       "Value" : "73.62"
     },
     "Total Dissolved Solids" : {
       "Last Updated At" : "1646925104",
       "Value" : "16"
     },
     "Turbidity" : {
       "Last Updated At" : "1646925104",
       "Value" : "0"
     },
     "Water Level" : {
       "Last Updated At" : "1646925104",
       "Value" : "0.96"
     }
   },
   "Interval Log 5min" : {
     "-MxpSVSLIIcb2jesDd_i" : {
       "Temperature" : "73.62",
       "Timestamp" : "1646925143",
       "Total Dissolved Solids" : "15",
       "Turbidity" : "3000",
       "Water Level" : "0.14"
     },
     "-MxpSgbYypJhw0qMFpbb" : {
       "Temperature" : "73.62",
       "Timestamp" : "1646925193",
       "Total Dissolved Solids" : "15",
       "Turbidity" : "3000",
       "Water Level" : "0.47"
     }
   },
   "Mock Data Log" : {
     "1646925143" : {
       "Temperature" : 73.625,
       "Timestamp" : 1646943144048,
       "Total Dissolved Solids" : 15,
       "Turbidity" : 3000,
       "Water Level" : 0.1437
     },
     "1646925193" : {
       "Temperature" : 73.625,
       "Timestamp" : 1646943193858,
       "Total Dissolved Solids" : 15,
       "Turbidity" : 3000,
       "Water Level" : 0.47165
     }
   },
   "Pond Parameters" : {
     "Temperature" : 73.625,
     "Total Dissolved Solids" : 15,
     "Turbidity Value" : 0,
     "Turbidity Voltage" : 4.8547,
     "Water Level" : 1.83031
   }
 }
 
 
 */


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

// MARK: - PondParameters: Original current working model
struct PondParameters: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    let temperature: Double
    let totalDissolvedSolids, turbidityValue: Int
    let turbidityVoltage, waterLevel: Double
    let pH: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "Temperature"
        case totalDissolvedSolids = "Total Dissolved Solids"
        case turbidityValue = "Turbidity Value"
        case turbidityVoltage = "Turbidity Voltage"
        case waterLevel = "Water Level"
        case pH = "pH"
    }
}
