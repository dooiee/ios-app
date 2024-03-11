//
//  FirebaseDataRetreivalForInterval.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 4/26/22.
//

import Foundation
import Firebase
import Combine
import FirebaseSharedSwift
import OrderedCollections
import SwiftUI

struct FirebaseTimeIntervalGeneric {
    var returnedParameterValuesForInterval: OrderedDictionary<String, Double>? = nil
    var returnedErrorValuesForInterval: Bool? = false
}

enum FirebaseDataRetreivalResult: Error {
    case failure(String)
}

struct AverageValueAndCountForInterval {
    var averageValue: OrderedDictionary<String, Double> = [:]
    var dataCount: [String: Int] = [:]
    
//    mutating func averageForEachDateFormatterKey(for timestampFormatterDay: Int, parameter: Double) { // commented out
    mutating func averageForEachDateFormatterKey(for timestampFormatterDay: String, parameter: Double) {
        if averageValue[timestampFormatterDay] == nil {
            dataCount[timestampFormatterDay] = 1
            averageValue[timestampFormatterDay] = parameter
        } else {
            guard let meanNMinusOne = averageValue.removeValue(forKey: timestampFormatterDay) else { return }
            guard var dataCountPerDay = dataCount.removeValue(forKey: timestampFormatterDay) else { return }
            dataCountPerDay += 1
            let updatedMean = meanNMinusOne + ((parameter - meanNMinusOne)/Double(dataCountPerDay))
//            print("\(updatedMean) = \(meanNMinusOne) + (\(parameter) - \(meanNMinusOne)) / \(Double(dataCountPerDay))") // working print to make sure all parts of equation are being retreived correctly.
            dataCount.updateValue(dataCountPerDay, forKey: timestampFormatterDay)
            averageValue.updateValue(updatedMean, forKey: timestampFormatterDay)
        }
    }
}

// simplified version of the above struct
//struct AverageValueAndCountForInterval {
//    var averageValue = OrderedDictionary<String, Double>()
//    var dataCount = [String: Int]()
//    
//    mutating func averageForEachDateFormatterKey(for timestampFormatterDay: String, parameter: Double) {
//        if averageValue[timestampFormatterDay] == nil {
//            averageValue[timestampFormatterDay] = parameter
//            dataCount[timestampFormatterDay] = 1
//        } else {
//            guard let meanNMinusOne = averageValue.removeValue(forKey: timestampFormatterDay),
//                  var dataCountPerDay = dataCount.removeValue(forKey: timestampFormatterDay) else { return }
//            dataCountPerDay += 1
//            let updatedMean = meanNMinusOne + ((parameter - meanNMinusOne) / Double(dataCountPerDay))
//            dataCount[timestampFormatterDay] = dataCountPerDay
//            averageValue[timestampFormatterDay] = updatedMean
//        }
//    }
//}

class AverageValueAndCountForIntervalClass {
    var averageValue: OrderedDictionary<String, Double> = [:]
    var dataCount: [String: Int] = [:]
    
    //    mutating func averageForEachDateFormatterKey(for timestampFormatterDay: Int, parameter: Double) { // commented out
    func averageForEachDateFormatterKey(for timestampFormatterDay: String, parameter: Double) {
        if averageValue[timestampFormatterDay] == nil {
            dataCount[timestampFormatterDay] = 1
            averageValue[timestampFormatterDay] = parameter
        } else {
            guard let meanNMinusOne = averageValue.removeValue(forKey: timestampFormatterDay) else { return }
            guard var dataCountPerDay = dataCount.removeValue(forKey: timestampFormatterDay) else { return }
            dataCountPerDay += 1
            let updatedMean = meanNMinusOne + ((parameter - meanNMinusOne)/Double(dataCountPerDay))
        //  print("\(updatedMean) = \(meanNMinusOne) + (\(parameter) - \(meanNMinusOne)) / \(Double(dataCountPerDay))") // working print to make sure all parts of equation are being retreived correctly.
            dataCount.updateValue(dataCountPerDay, forKey: timestampFormatterDay)
            averageValue.updateValue(updatedMean, forKey: timestampFormatterDay)
        }
    }
}

public class FirebaseDataRetreivalForInterval: ObservableObject {
    
    @Published var returnedParameterValuesForTimeInterval = FirebaseTimeIntervalGeneric()
    @Published var mockDataLog = [MockDataLog]()
    @Published var sensorDataLog = [SensorDataLog]()
    @Published var timestamps1M: [Int] = []
    @Published var temperature1M: [Double] = []
    @Published var waterLevel1M: [Double] = []
    @Published var turbidity1M: [Double] = []
    @Published var tds1M: [Double] = []
    @Published var ph1M: [Double] = []
    @Published var oneMonthSortedDictionary2: OrderedDictionary<Int, Double> = [:] // commented out
    @Published var oneMonthSortedDictionary: OrderedDictionary<String, Double> = [:] // added
    @Published var temperatureSortedDictionary: OrderedDictionary<String, Double> = [:] // added
    @Published var waterlevelSortedDictionary: OrderedDictionary<String, Double> = [:] // added
    @Published var turbiditySortedDictionary: OrderedDictionary<String, Double> = [:] // added
    @Published var tdsSortedDictionary: OrderedDictionary<String, Double> = [:] // added
    @Published var phSortedDictionary: OrderedDictionary<String, Double> = [:] // added
    
    @Published var timestampsFiltered1H: [Int] = []
    @Published var timestampsFiltered1H2: [String] = []
    @Published var temperatureFiltered1H: [Double] = []
    @Published var timestampsFiltered1W: [Int] = []
    @Published var temperatureFiltered1W: [Double] = []
    @Published var timestampsFiltered1M: [String] = [] // added
    @Published var temperatureFiltered1M: [Double] = []
    @Published var threeMonthSortedDictionary: OrderedDictionary<Int, Double> = [:]
    @Published var timestampsFiltered3M: [Int] = []
    @Published var temperatureFiltered3M: [Double] = []
    
    @Published var temperatures1Week: [Double]? = nil
    
    @Published var returnedParameterValuesFor1H: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesFor1D: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesFor1DError: Bool = false
    @Published var returnedParameterValuesFor1W: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesFor1M: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesFor3M: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesFor6M: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesFor1Y: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesForAll: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesForInterval: OrderedDictionary<String, Double>? = nil // added
    
    let lastDayInterval: Int = 1_000*60*60*24
    let lastWeekInterval: Int = 1_000*60*60*24*7
    let lastMonthInterval: Int = 1_000*60*60*24*30
    let lastThreeMonthsInterval: Int = 1_000*60*60*24*90

    init() {}
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
    var averageValueAndCountForInterval = AverageValueAndCountForInterval()
    var averageValueAndCountForIntervalClass = AverageValueAndCountForIntervalClass()
    var averageValueAndCountForIntervalClass2 = AverageValueAndCountForIntervalClass()
    var averageValueAndCountForIntervalClass3 = AverageValueAndCountForIntervalClass()
    var averageValueAndCountForIntervalClass4 = AverageValueAndCountForIntervalClass()
    var averageValueAndCountForIntervalClass5 = AverageValueAndCountForIntervalClass()
    
    func fetchFirebaseDataForInterval(parameter: String, for interval: Int) -> () {
        returnFirebaseDataForInterval(parameter: parameter, for: interval, completion: { [weak self] parameter, error in
            if let returnedParameterValuesForInterval = parameter {
                self?.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval = returnedParameterValuesForInterval
                 switch interval {
                 case 1_000*60*60:
                     self?.returnedParameterValuesFor1H = returnedParameterValuesForInterval
                 case 1_000*60*60*23: // changed to 23 from 24 to stop values from 24 hours ago affect current hour average which yielded incorrect plot value.
                     self?.returnedParameterValuesFor1D = returnedParameterValuesForInterval
                 case 1_000*60*60*24*7:
                     self?.returnedParameterValuesFor1W = returnedParameterValuesForInterval
                 case 1_000*60*60*24*30:
                     self?.returnedParameterValuesFor1M = returnedParameterValuesForInterval
                 case 1_000*60*60*24*90:
                     self?.returnedParameterValuesFor3M = returnedParameterValuesForInterval
                 case 1_000*60*60*24*180:
                     self?.returnedParameterValuesFor6M = returnedParameterValuesForInterval
                 case 1_000*60*60*24*365:
                     self?.returnedParameterValuesFor1Y = returnedParameterValuesForInterval
                 case Int(Date().timeIntervalSinceReferenceDate*1_000):
                     self?.returnedParameterValuesForAll = returnedParameterValuesForInterval
                 default:
                     self?.returnedParameterValuesForAll = returnedParameterValuesForInterval
                 }
            }
            if let error = error {
                print("\(error)")
                self?.returnedParameterValuesForTimeInterval.returnedErrorValuesForInterval = true
            }
        })
    }
    
    func returnFirebaseDataForInterval(parameter: String, for interval: Int, completion: @escaping (_ parameter: OrderedDictionary<String, Double>?, _ error: Error?) -> Void) {
        // Capture the start time
        let startTime = CFAbsoluteTimeGetCurrent()

        let sensorDataLogRef = Database.database().reference(withPath: "Log/SensorData")
        let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
        let timestampInterval = currentUnixTimestampLong - interval
        var sortedDictionaryValueForFormattedTimestampKey: OrderedDictionary<String, Double> = [:]
        var parametersForInterval = [Double]()
        
        // This switch case is based on the title string for each sensor detail view.
        var dataParameterCodingKey: String?
        switch parameter {
        case "Temperature":
            dataParameterCodingKey = SensorDataLog.CodingKeys.temperature.rawValue
        case "Pond Depth", "Water Level":
            dataParameterCodingKey = SensorDataLog.CodingKeys.waterLevel.rawValue
        case "Turbidity":
            dataParameterCodingKey = SensorDataLog.CodingKeys.turbidity.rawValue
        case "TDS", "Total Dissolved Solids":
            dataParameterCodingKey = SensorDataLog.CodingKeys.totalDissolvedSolids.rawValue
        case "pH":
            dataParameterCodingKey = SensorDataLog.CodingKeys.pH.rawValue
        default:
            dataParameterCodingKey = SensorDataLog.CodingKeys.temperature.rawValue
        }
        let dateFormat: String?
        switch interval {
        case 1_000*60*60:
            dateFormat = "h:mm a"
        case 1_000*60*60*23:
            dateFormat = "h:00 a"
        case 1_000*60*60*24*7:
            dateFormat = "h:00 a, MMM d"
        case 1_000*60*60*24*30, 1_000*60*60*24*90, 1_000*60*60*24*180, 1_000*60*60*24*365:
            dateFormat = "MMM d, YYYY"
        case Int(Date().timeIntervalSinceReferenceDate*1_000):
            dateFormat = "MMM w, YYYY"
        default:
            dateFormat = nil
        }
        
        // clears mutating func result to stop plots from plotting multiple intervals
        if !self.averageValueAndCountForInterval.averageValue.isEmpty { 
            self.averageValueAndCountForInterval.averageValue = [:]
        }
        if (self.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval != nil) {
            self.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval = nil
        }
        
        databaseHandle = sensorDataLogRef.queryOrdered(byChild: "timestamp").queryStarting(afterValue: timestampInterval).observe(.value, with: { snapshot in
            if snapshot.exists() {
                for item in snapshot.children {
                    if let item = item as? DataSnapshot {
                        guard let data = item.value as? [String: Any] else { return }
                        if item.childrenCount >= 6 {
                            let values = data.map({ ($0.value) })
                            let keys = data.map({ ($0.key) })
                            let timestamp = values[keys.firstIndex(of: SensorDataLog.CodingKeys.timestamp.rawValue)!] as! Int
                            if dataParameterCodingKey != nil {
                                let dataParameter = values[keys.firstIndex(of: dataParameterCodingKey!)!] as! Double
                                if let dateFormat = dateFormat { // returns an average of parameters values specified by the date formatted value (i.e. each day, each week, each hour, etc., and then calculates and updates a running average for each unique dictionary key.
                                    let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
                                    let timestampFormatter = DateFormatter()
                                        timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
                                        timestampFormatter.locale = NSLocale.current
                                        timestampFormatter.dateFormat = dateFormat //Specify your format that you want
                                    let timestampsFiltered = timestampFormatter.string(from: date) // added
                                    self.averageValueAndCountForInterval.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: dataParameter) // run function to get running average
                                    sortedDictionaryValueForFormattedTimestampKey = self.averageValueAndCountForInterval.averageValue
                                    parametersForInterval = sortedDictionaryValueForFormattedTimestampKey.values.elements
                                } else { // returns all parameter values for the time interval provided
                                    print("no time interval specified")
                                    parametersForInterval.append(dataParameter)
                                }
                            }
                        }
                    }
                }
                completion(sortedDictionaryValueForFormattedTimestampKey, nil)
                print(sortedDictionaryValueForFormattedTimestampKey)
                self.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval = sortedDictionaryValueForFormattedTimestampKey
            }
            else {
                completion(nil, FirebaseDataRetreivalResult.failure("Completion is empty, no data returned."))
                self.returnedParameterValuesForTimeInterval.returnedErrorValuesForInterval = true
            }
            
            // Capture the end time
            let endTime = CFAbsoluteTimeGetCurrent()

            // Calculate and print the elapsed time
            let elapsedTime = endTime - startTime
            print("Elapsed time: \(elapsedTime) seconds")
            
            sensorDataLogRef.removeAllObservers()
        }) // databaseHandle
    } // func

    func clearFetchedFirebaseDataForIntervals() {
        self.returnedParameterValuesFor1H = nil
        self.returnedParameterValuesFor1D = nil
        self.returnedParameterValuesFor1W = nil
        self.returnedParameterValuesFor1M = nil
        self.returnedParameterValuesFor3M = nil
        self.returnedParameterValuesFor1Y = nil
        self.returnedParameterValuesForAll = nil
        self.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval = nil
        print("Parameter Values Cleared!")
    }
    
    //TODO: Need to figure out how to pop first value when the day repeats so I'm not averaging todays temperature with the values on the same day from a month ago. Perhaps a solution is to make dictionary value a string/date/or int that includes the month (i.e. 329 for march 29th so then when april 29th comes up the new dictionary value is 429 and we can pop the 329 values off.
    /// this appears to work where last month of same day does not merge with this months because keys are not the same. Would just change Int to string so I can display the keys on the plot. Would have to just not convery timestamp from string back to int.
    func returnFirebaseDataForWidget(for interval: Int) { // equals the other one so querying helps reduce amount of data we need to fetch
        print("Returning Firebase Data for Widget...")
        
        let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
        let timestampInterval = currentUnixTimestampLong - interval
        let sensorDataLogRef = Database.database().reference(withPath: "Log/SensorData")
        
        do {
            databaseHandle = sensorDataLogRef.queryOrdered(byChild: "timestamp").queryStarting(afterValue: timestampInterval).observe(.childAdded) { (snapshot) in
                
                guard let data = snapshot.value as? [String: Any] else { return }
                    if data.count >= 6 {
                        let values = data.map({ ($0.value) })
                        let keys = data.map({ ($0.key) })
                        
                        let temperature = values[keys.firstIndex(of: SensorDataLog.CodingKeys.temperature.rawValue)!] as! Double
                        let timestamp = values[keys.firstIndex(of: SensorDataLog.CodingKeys.timestamp.rawValue)!] as! Int
                        let tds = values[keys.firstIndex(of: SensorDataLog.CodingKeys.totalDissolvedSolids.rawValue)!] as! Int
                        let turbidity = values[keys.firstIndex(of: SensorDataLog.CodingKeys.turbidity.rawValue)!] as! Int
                        // let turbidityVoltage = values[keys.firstIndex(of: SensorDataLog.CodingKeys.turbidityVoltage.rawValue)!] as! Double
                        let waterlevel = values[keys.firstIndex(of: SensorDataLog.CodingKeys.waterLevel.rawValue)!] as! Double
                        let ph = values[keys.firstIndex(of: SensorDataLog.CodingKeys.pH.rawValue)!] as! Double
                        self.sensorDataLog = [SensorDataLog(temperature: temperature, timestamp: timestamp, totalDissolvedSolids: tds, turbidity: turbidity, waterLevel: waterlevel, pH: ph)]
                        if timestamp > timestampInterval {
                            let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
                            let timestampFormatter = DateFormatter()
                                timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
                                timestampFormatter.locale = NSLocale.current
                                // timestampFormatter.dateFormat = "Mdd" //Specify your format that you want
                                timestampFormatter.dateFormat = "MMM d, YYYY"
                            let timestampsFiltered = timestampFormatter.string(from: date)
                            
                            for i in (1...5) {
                                switch i {
                                case 1:
                                    self.averageValueAndCountForIntervalClass.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: temperature)
                                    self.temperatureSortedDictionary = self.averageValueAndCountForIntervalClass.averageValue
                                    break
                                case 2:
                                    self.averageValueAndCountForIntervalClass2.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: waterlevel)
                                    self.waterlevelSortedDictionary = self.averageValueAndCountForIntervalClass2.averageValue
                                    break
                                case 3:
                                    self.averageValueAndCountForIntervalClass3.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: Double(turbidity))
                                    self.turbiditySortedDictionary = self.averageValueAndCountForIntervalClass3.averageValue
                                    break
                                case 4:
                                    self.averageValueAndCountForIntervalClass4.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: Double(tds))
                                    self.tdsSortedDictionary = self.averageValueAndCountForIntervalClass4.averageValue
                                    break
                                case 5:
                                    self.averageValueAndCountForIntervalClass5.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: ph)
                                    self.phSortedDictionary = self.averageValueAndCountForIntervalClass5.averageValue
                                    break
                                default:
                                    print("default case")
                                }
                            }

                            self.timestampsFiltered1M = self.oneMonthSortedDictionary.keys.elements
                            self.temperatureFiltered1M = self.oneMonthSortedDictionary.values.elements
                        }
                    }
            } // databaseHandle
        }
    } // func
}
