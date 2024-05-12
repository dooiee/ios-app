//
//  DataRetreiver.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 5/11/24.
//

import Foundation
import Firebase
import Combine
import OrderedCollections
import SwiftUI

class SensorDataManager: ObservableObject {
    enum DataFetchState: Equatable {
        case idle, loading, loaded, error(String)
    }
    
    @Published var sensorData = [String: OrderedDictionary<String, Double>]()
    @Published var state: DataFetchState = .idle
    
    let formatter = DateFormatter()
    let ref = Database.database().reference(withPath: "Log/SensorData")
    
    init() {
        formatter.timeZone = TimeZone(abbreviation: "EST")
        formatter.locale = NSLocale.current
    }
    
    // Clear all fetched data
    func clearFetchedData() {
        DispatchQueue.main.async {
            self.sensorData.removeAll()
            self.state = .idle  // Reset the state to idle, indicating no current data or operation
        }
//        sensorData.removeAll()
    }

    func stopFetchingData() {
        // // suggestion 1: remove all observers
        // ref.removeAllObservers()

        // // suggestion 2: remove observer with handle
        // if let handle = databaseHandle {
        //     ref.removeObserver(withHandle: handle)
        // }
    }

    func fetchSensorData(parameter: String, interval: TimeInterval) {
        self.state = .loading
        let intervalKey = getKeyForInterval(interval)
        let dateFormat = getFormatForInterval(interval)
        formatter.dateFormat = dateFormat
        
        let timestampThreshold = Int(Date().timeIntervalSince1970*1_000) - Int(interval)
        ref.queryOrdered(byChild: "timestamp")
            .queryStarting(afterValue: timestampThreshold)
            .observeSingleEvent(of: .value, with: { [weak self] snapshot in
                guard let self = self else { return }
                if snapshot.exists() && snapshot.childrenCount > 0 {
                    self.processSnapshot(snapshot, for: parameter, using: intervalKey)
                } else {
                    DispatchQueue.main.async {
                        self.state = .error("No data available for this interval")
                    }
//                    self.state = .error("No data available for this interval")
                }
            })
    }
    
    private func processSnapshot(_ snapshot: DataSnapshot, for parameter: String, using intervalKey: String) {
        var averages = OrderedDictionary<String, Double>()
        var counts = [String: Int]()
        guard let parameterKey = databaseKey(for: parameter) else {
            DispatchQueue.main.async {
                self.state = .error("Invalid parameter specified: \(parameter)")
            }
            return
        }
        
        for child in snapshot.children.allObjects as! [DataSnapshot] {
//            print("Child: \(child)")
            if let data = child.value as? [String: Any],
               let timestamp = data["timestamp"] as? Int,
               let value = data[parameterKey] as? Double {
                let date = Date(timeIntervalSince1970: Double(timestamp / 1_000))
                let key = formatter.string(from: date)
                
                counts[key, default: 0] += 1
                let count = counts[key]!
                averages[key] = (averages[key] ?? 0) + ((value - (averages[key] ?? 0)) / Double(count))
            }
        }
//        print("Average: \(averages)")
//        print("Counts: \(counts)")
        
        DispatchQueue.main.async {
            if averages.isEmpty {
                self.state = .error("No data available for this interval")
            } else {
                self.sensorData[intervalKey] = averages
                print("sensorData: \(self.sensorData)")
                self.state = .loaded
            }
        }
    }
    
    private func getKeyForInterval(_ interval: TimeInterval) -> String {
        switch interval {
        case 1_000*60*60:
            return "1H"
        case 1_000*60*60*23, 1_000*60*60*24:
            return "1D"
        case 1_000*60*60*24*7:
            return "1W"
        case 1_000*60*60*24*30:
            return "1M"
        case 1_000*60*60*24*90:
            return "3M"
        case 1_000*60*60*24*180:
            return "6M"
        case 1_000*60*60*24*365:
            return "1Y"
        default:
            return "All"
        }
    }
    
    private func getFormatForInterval(_ interval: TimeInterval) -> String {
        switch interval {
        case 1_000*60*60:
            return "h:mm a"
        case 1_000*60*60*23, 1_000*60*60*24:
            return "h:00 a"
        case 1_000*60*60*24*7:
            return "h:00 a, MMM d"
        case 1_000*60*60*24*30, 1_000*60*60*24*90, 1_000*60*60*24*180, 1_000*60*60*24*365:
            return "MMM d, YYYY"
        default: // All data case
            return "MMM w, YYYY"
        }
    }
    
    func databaseKey(for parameter: String) -> String? {
        switch parameter {
        case "Temperature":
            return PondParameters.CodingKeys.temperature.rawValue
        case "Pond Depth", "Water Level":
            return PondParameters.CodingKeys.waterLevel.rawValue
        case "Turbidity":
            return PondParameters.CodingKeys.turbidityValue.rawValue
        case "TDS", "Total Dissolved Solids":
            return PondParameters.CodingKeys.totalDissolvedSolids.rawValue
        case "pH":
            return PondParameters.CodingKeys.pH.rawValue
        default:
            return nil
        }
    }
}
