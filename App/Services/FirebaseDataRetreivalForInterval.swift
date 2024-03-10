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
    /* copied function with return to change one above to no return
     mutating func averageForEachDayOfMonth(for timestampFormatterDay: Int, parameter: Double) -> OrderedDictionary<Int, Double> {
         if averageValue[timestampFormatterDay] == nil {
             dataCount[timestampFormatterDay] = 1
             averageValue[timestampFormatterDay] = parameter
             return [timestampFormatterDay: parameter]
 //            print("if: \(averageValue)")
         } else {
             guard let meanNMinusOne = averageValue.removeValue(forKey: timestampFormatterDay) else { return [:] }
             guard var dataCountPerDay = dataCount.removeValue(forKey: timestampFormatterDay) else { return [:] }
             dataCountPerDay += 1
             let updatedMean = meanNMinusOne + ((parameter - meanNMinusOne)/Double(dataCountPerDay))
 //            print("\(updatedMean) = \(meanNMinusOne) + (\(parameter) - \(meanNMinusOne)) / \(Double(dataCountPerDay))") // working print to make sure all parts of equation are being retreived correctly.
             dataCount.updateValue(dataCountPerDay, forKey: timestampFormatterDay)
             averageValue.updateValue(updatedMean, forKey: timestampFormatterDay)
 //            print("mean(n): \(averageValue)")
 //            print("dataCountVar \(dataCount)") // this print displays the total counted values for each day. i.e. (dataCountVar [12: 2742, 17: 2736, 31: 2664, ... ]
             return [timestampFormatterDay: updatedMean]
         }
     }
     */
}

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
//            print("\(updatedMean) = \(meanNMinusOne) + (\(parameter) - \(meanNMinusOne)) / \(Double(dataCountPerDay))") // working print to make sure all parts of equation are being retreived correctly.
            dataCount.updateValue(dataCountPerDay, forKey: timestampFormatterDay)
            averageValue.updateValue(updatedMean, forKey: timestampFormatterDay)
        }
    }
    /* copied function with return to change one above to no return
     mutating func averageForEachDayOfMonth(for timestampFormatterDay: Int, parameter: Double) -> OrderedDictionary<Int, Double> {
         if averageValue[timestampFormatterDay] == nil {
             dataCount[timestampFormatterDay] = 1
             averageValue[timestampFormatterDay] = parameter
             return [timestampFormatterDay: parameter]
 //            print("if: \(averageValue)")
         } else {
             guard let meanNMinusOne = averageValue.removeValue(forKey: timestampFormatterDay) else { return [:] }
             guard var dataCountPerDay = dataCount.removeValue(forKey: timestampFormatterDay) else { return [:] }
             dataCountPerDay += 1
             let updatedMean = meanNMinusOne + ((parameter - meanNMinusOne)/Double(dataCountPerDay))
 //            print("\(updatedMean) = \(meanNMinusOne) + (\(parameter) - \(meanNMinusOne)) / \(Double(dataCountPerDay))") // working print to make sure all parts of equation are being retreived correctly.
             dataCount.updateValue(dataCountPerDay, forKey: timestampFormatterDay)
             averageValue.updateValue(updatedMean, forKey: timestampFormatterDay)
 //            print("mean(n): \(averageValue)")
 //            print("dataCountVar \(dataCount)") // this print displays the total counted values for each day. i.e. (dataCountVar [12: 2742, 17: 2736, 31: 2664, ... ]
             return [timestampFormatterDay: updatedMean]
         }
     }
     */
}

public class FirebaseDataRetreivalForInterval: ObservableObject {
    
    @Published var returnedParameterValuesForTimeInterval = FirebaseTimeIntervalGeneric()
    @Published var mockDataLog = [MockDataLog]()
    @Published var timestamps1M: [Int] = []
    @Published var temperature1M: [Double] = []
    @Published var waterLevel1M: [Double] = []
    @Published var turbidity1M: [Double] = []
    @Published var tds1M: [Double] = []
    @Published var ph1M: [Double] = []
//    @Published var oneMonthSortedDictionary: OrderedDictionary<Int, Double> = [:] // commented out
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
//    @Published var timestampsFiltered1M: [Int] = [] // commented out
    @Published var timestampsFiltered1M: [String] = [] // added
    @Published var temperatureFiltered1M: [Double] = []
    @Published var threeMonthSortedDictionary: OrderedDictionary<Int, Double> = [:]
    @Published var timestampsFiltered3M: [Int] = []
    @Published var temperatureFiltered3M: [Double] = []
    
    @Published var temperatures1Week: [Double]? = nil
    
    @Published var returnedParameterValuesFor1H: OrderedDictionary<String, Double>? = nil
    @Published var returnedParameterValuesFor1D: OrderedDictionary<String, Double>? = nil
//    @Published var returnedParameterValuesFor1D: FirebaseDataRetreivalResult
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

    init() {
        returnFirebaseDataOneHour()
    }
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
    var averageValueAndCountForInterval = AverageValueAndCountForInterval()
    var averageValueAndCountForIntervalClass = AverageValueAndCountForIntervalClass()
    var averageValueAndCountForIntervalClass2 = AverageValueAndCountForIntervalClass()
    var averageValueAndCountForIntervalClass3 = AverageValueAndCountForIntervalClass()
    var averageValueAndCountForIntervalClass4 = AverageValueAndCountForIntervalClass()
    var averageValueAndCountForIntervalClass5 = AverageValueAndCountForIntervalClass()
    
//    func fetchFirebaseDataForInterval(parameter: String, for interval: Int) -> OrderedDictionary<String, Double> {
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
 //                    self?.returnedParameterValuesForInterval = returnedParameterValuesForInterval
                     self?.returnedParameterValuesForAll = returnedParameterValuesForInterval
                 }
            }
            if let error = error {
                print("\(error)")
                self?.returnedParameterValuesForTimeInterval.returnedErrorValuesForInterval = true
            }
        })
    }
    
    func clearFetchedFirebaseDataForIntervals() {
        self.returnedParameterValuesFor1H = nil
        self.returnedParameterValuesFor1D = nil
        self.returnedParameterValuesFor1W = nil
        self.returnedParameterValuesFor1M = nil
        self.returnedParameterValuesFor3M = nil
//        self.returnedParameterValuesFor6M = nil
        self.returnedParameterValuesFor1Y = nil
        self.returnedParameterValuesForAll = nil
        self.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval = nil
        print("Parameter Values Cleared!")
//        print("Parameter Values Cleared! : \(self.returnedParameterValuesFor1H) \(self.returnedParameterValuesFor1D) \(self.returnedParameterValuesFor1W) \(self.returnedParameterValuesFor1M) \(self.returnedParameterValuesFor3M) \(self.returnedParameterValuesFor1Y) \(self.returnedParameterValuesForAll)")
    }
    
    // using this function to quickly retreive data when detailed parameter plots page is shown
    func returnFirebaseDataOneHour() {
        print("Returning Last Hour Firebase Data...")
        
        let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
        let interval = 1_000*60*60
        let timestampInterval = currentUnixTimestampLong - interval
        let sensorDataLogRef = Database.database().reference(withPath: "Sensor Data Log")
        
        databaseHandle = sensorDataLogRef.queryOrdered(byChild: "Timestamp").queryStarting(afterValue: timestampInterval).observe(.childAdded) { (snapshot) in
            
            guard let data = snapshot.value as? [String: Any], data.count == 6 else { return }
//                if data.count == 5 {
                    let values = data.map({ ($0.value) })
                    let keys = data.map({ ($0.key) })
                    
                    let temperature = values[keys.firstIndex(of: MockDataLog.CodingKeys.temperature.rawValue)!] as! Double
                    let timestamp = values[keys.firstIndex(of: MockDataLog.CodingKeys.timestamp.rawValue)!] as! Int
//                    let tds = values[keys.firstIndex(of: MockDataLog.CodingKeys.totalDissolvedSolids.rawValue)!] as! Int
//                    let turbidity = values[keys.firstIndex(of: MockDataLog.CodingKeys.turbidity.rawValue)!] as! Int
//                    let waterlevel = values[keys.firstIndex(of: MockDataLog.CodingKeys.waterLevel.rawValue)!] as! Double

//                    self.mockDataLog = [MockDataLog(temperature: temperature, timestamp: timestamp, totalDissolvedSolids: tds, turbidity: turbidity, waterLevel: waterlevel)]
                    self.timestampsFiltered1H.append(timestamp)
                    self.temperatureFiltered1H.append(temperature)
            
        
            if self.timestampsFiltered1H.first! < timestampInterval {
//                self.timestampsFiltered1H.removeAll(where: {$0 < timestampInterval})
                    print("values removed: \(self.timestampsFiltered1H.removeAll(where: {$0 < timestampInterval}))")
                let outOfTimestamp = self.timestampsFiltered1H.removeFirst()
                print("first value removed: \(outOfTimestamp)")
            }
//                    print("temperatureFiltered1H: \(self.temperatureFiltered1H)")
//                }
        } // databaseHandle
    } // func
    
    //MARK: This function works and fetches data very fast, can be used to populate data values on init very quickly
    // can either return a dictionary showing the averaged values for key or I can return an array of parameters values
    
//    func returnFirebaseDataForInterval(parameter: String, for interval: Int, completion: @escaping (_ parameter: OrderedDictionary<String, Double>?, _ error: Error?) -> Void) -> OrderedDictionary<String, Double> {
    func returnFirebaseDataForInterval(parameter: String, for interval: Int, completion: @escaping (_ parameter: OrderedDictionary<String, Double>?, _ error: Error?) -> Void) {

        let dateFormat: String?

        switch interval {
        case 1_000*60*60:
            print("Returning Firebase Data for last hour...")
            dateFormat = "h:mm a"
        case 1_000*60*60*23:
            print("Returning Firebase Data for last 24 hours...")
            dateFormat = "h:00 a"
        case 1_000*60*60*24*7:
            print("Returning Firebase Data for last 7 days...")
            dateFormat = "h:00 a, MMM d"
        case 1_000*60*60*24*30:
            print("Returning Firebase Data for last 30 days...")
            dateFormat = "MMM d, YYYY"
        case 1_000*60*60*24*90:
            print("Returning Firebase Data for last 3 months...")
            dateFormat = "MMM d, YYYY"
        case 1_000*60*60*24*180:
            print("Returning Firebase Data for last 6 months...")
            dateFormat = "MMM d, YYYY"
        case 1_000*60*60*24*365:
            print("Returning Firebase Data for last 12 months...")
            dateFormat = "MMM d, YYYY"
        case Int(Date().timeIntervalSinceReferenceDate*1_000):
            print("Returning All Firebase Data ever recorded...")
            dateFormat = "MMM w, YYYY"
        default:
//            print("Returning Firebase Data for some unspecified time interval...")
//            dateFormat = nil
            print("Returning All Firebase Data ever recorded...")
            dateFormat = "MMM, YYYY"
//            let dateFormat = nil
        }
//        var dataParameter: Double
        var dataParameterCodingKey: String?
        switch parameter {
        case "Temperature":
            dataParameterCodingKey = MockDataLog.CodingKeys.temperature.rawValue
            break
        case "Pond Depth" :
            dataParameterCodingKey = MockDataLog.CodingKeys.waterLevel.rawValue
            break
        case "Water Level" :
            dataParameterCodingKey = MockDataLog.CodingKeys.waterLevel.rawValue
            break
        case "Turbidity" :
            dataParameterCodingKey = MockDataLog.CodingKeys.turbidity.rawValue
            break
        case "TDS" :
            dataParameterCodingKey = MockDataLog.CodingKeys.totalDissolvedSolids.rawValue
            break
        case "Total Dissolved Solids" :
            dataParameterCodingKey = MockDataLog.CodingKeys.totalDissolvedSolids.rawValue
            break
        case "pH" :
            dataParameterCodingKey = MockDataLog.CodingKeys.pH.rawValue
            break
        default:
            dataParameterCodingKey = MockDataLog.CodingKeys.temperature.rawValue
            break
        }
        
        let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
        let timestampInterval = currentUnixTimestampLong - interval
        let sensorDataLogRef = Database.database().reference(withPath: "Sensor Data Log")
        var parametersForInterval = [Double]()
//        var filteredDatesForInterval = [String]()
        
//        var sortedDictionaryValueForFormattedTimestampKey: OrderedDictionary<String, Int> = [:] // commented out
        var sortedDictionaryValueForFormattedTimestampKey: OrderedDictionary<String, Double> = [:]
//        var sortedDictionaryValueForFormattedTimestampKey: OrderedDictionary<String, Double>? = nil
        
        if !self.averageValueAndCountForInterval.averageValue.isEmpty { // clears mutating func result to stop plots from plotting multiple intervals
            self.averageValueAndCountForInterval.averageValue = [:]
//            print("if self.averageValueAndCountForInterval.averageValue \(self.averageValueAndCountForInterval.averageValue)")
        }
        if (self.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval != nil) {
            self.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval = nil
        }
        
        databaseHandle = sensorDataLogRef.queryOrdered(byChild: "Timestamp").queryStarting(afterValue: timestampInterval).observe(.value, with: { snapshot in
            if snapshot.exists() {
                for item in snapshot.children {
                    if let item = item as? DataSnapshot {
                        guard let data = item.value as? [String: Any] else { return }
                        if item.childrenCount == 6 {
                            let values = data.map({ ($0.value) })
        //                    print(values)
                            let keys = data.map({ ($0.key) })
        //                    print(keys)
                            let timestamp = values[keys.firstIndex(of: MockDataLog.CodingKeys.timestamp.rawValue)!] as! Int
                            if dataParameterCodingKey != nil {
                                let dataParameter = values[keys.firstIndex(of: dataParameterCodingKey!)!] as! Double
                                /*
        //                        let temperature = values[keys.firstIndex(of: MockDataLog.CodingKeys.temperature.rawValue)!] as! Double
             //                let tds = values[keys.firstIndex(of: MockDataLog.CodingKeys.totalDissolvedSolids.rawValue)!] as! Int
             //                let turbidity = values[keys.firstIndex(of: MockDataLog.CodingKeys.turbidity.rawValue)!] as! Int
        //                        let waterlevel = values[keys.firstIndex(of: MockDataLog.CodingKeys.waterLevel.rawValue)!] as! Double
             //                self.mockDataLog = [MockDataLog(temperature: temperature, timestamp: timestamp, totalDissolvedSolids: tds, turbidity: turbidity, waterLevel: waterlevel)]
        //                        self.timestampsFiltered1W.append(timestamp)
        //                        self.temperatureFiltered1W.append(temperature)
        //                        temperaturesOneWeek.append(temperature)
                                 */
                                if let dateFormat = dateFormat { // returns an average of parameters values specified by the date formatted value (i.e. each day, each week, each hour, etc., and then calculates and updates a running average for each unique dictionary key.
                                    let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
                                    let timestampFormatter = DateFormatter()
                                        timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
                                        timestampFormatter.locale = NSLocale.current
                                        timestampFormatter.dateFormat = dateFormat //Specify your format that you want
        //                            let timestampsFiltered = timestampFormatter.string(from: date).convertStringToInt() // commented out
                                    let timestampsFiltered = timestampFormatter.string(from: date) // added
                                    self.averageValueAndCountForInterval.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: dataParameter) // run function to get running average
                                    sortedDictionaryValueForFormattedTimestampKey = self.averageValueAndCountForInterval.averageValue
                                    parametersForInterval = sortedDictionaryValueForFormattedTimestampKey.values.elements
    //                                filteredDatesForInterval = sortedDictionaryValueForFormattedTimestampKey.keys.elements
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
//                completion(self.returnedParameterValuesForInterval, nil)
                
                switch interval {
                case 1_000*60*60:
                    print("Finished retreiving data for last hour")
                case 1_000*60*60*23:
                    print("Finished retreiving data for last 24 hours")
                case 1_000*60*60*24*7:
                    print("Finished retreiving data for last 7 days")
                case 1_000*60*60*24*30:
                    print("Finished retreiving data for last 30 days")
                case 1_000*60*60*24*90:
                    print("Finished retreiving data for last 3 months")
                case 1_000*60*60*24*180:
                    print("Finished retreiving data for last 6 months")
                case 1_000*60*60*24*365:
                    print("Finished retreiving data for last 12 months")
                case Int(Date().timeIntervalSinceReferenceDate*1_000):
                    print("Finished retreiving all data ever recorded")
                default:
                    print("Finished retreiving all data ever recorded")
                }
            }
            else {
                completion(nil, FirebaseDataRetreivalResult.failure("Completion is empty, no data returned."))
                self.returnedParameterValuesForTimeInterval.returnedErrorValuesForInterval = true
            }
//            print("parametersForInterval: \(parametersForInterval)")
            sensorDataLogRef.removeAllObservers()
        }) // databaseHandle
//        return sortedDictionaryValueForFormattedTimestampKey
    } // func
    
    
    //TODO: Need to figure out how to pop first value when the day repeats so I'm not averaging todays temperature with the values on the same day from a month ago. Perhaps a solution is to make dictionary value a string/date/or int that includes the month (i.e. 329 for march 29th so then when april 29th comes up the new dictionary value is 429 and we can pop the 329 values off.
    /// this appears to work where last month of same day does not merge with this months because keys are not the same. Would just change Int to string so I can display the keys on the plot. Would have to just not convery timestamp from string back to int.
    func returnFirebaseDataForWidget(for interval: Int) { // equals the other one so querying helps reduce amount of data we need to fetch
        print("Returning Firebase Data for Widget...")
        
        let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
        let timestampInterval = currentUnixTimestampLong - interval
        let sensorDataLogRef = Database.database().reference(withPath: "Sensor Data Log")
        
        do {
            databaseHandle = sensorDataLogRef.queryOrdered(byChild: "Timestamp").queryStarting(afterValue: timestampInterval).observe(.childAdded) { (snapshot) in
                
                guard let data = snapshot.value as? [String: Any] else { return }
                    if data.count == 6 {
                        let values = data.map({ ($0.value) })
//                        print("values: \(values)")
                        let keys = data.map({ ($0.key) })
//                        print("keys: \(keys)")
                        
                        let temperature = values[keys.firstIndex(of: MockDataLog.CodingKeys.temperature.rawValue)!] as! Double
                        let timestamp = values[keys.firstIndex(of: MockDataLog.CodingKeys.timestamp.rawValue)!] as! Int
                        let tds = values[keys.firstIndex(of: MockDataLog.CodingKeys.totalDissolvedSolids.rawValue)!] as! Int
                        let turbidity = values[keys.firstIndex(of: MockDataLog.CodingKeys.turbidity.rawValue)!] as! Int
                        let waterlevel = values[keys.firstIndex(of: MockDataLog.CodingKeys.waterLevel.rawValue)!] as! Double
                        let ph = values[keys.firstIndex(of: MockDataLog.CodingKeys.pH.rawValue)!] as! Double

                        self.mockDataLog = [MockDataLog(temperature: temperature, timestamp: timestamp, totalDissolvedSolids: tds, turbidity: turbidity, waterLevel: waterlevel, pH: ph)]
                        if timestamp > timestampInterval {
                            let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
                            let timestampFormatter = DateFormatter()
                                timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
                                timestampFormatter.locale = NSLocale.current
//                                timestampFormatter.dateFormat = "Mdd" //Specify your format that you want
                                timestampFormatter.dateFormat = "MMM d, YYYY"
//                            let timestampsFiltered = timestampFormatter.string(from: date).convertStringToInt() // commented out
                            let timestampsFiltered = timestampFormatter.string(from: date) // added
                            
//                            let startIntervalDate = Date(timeIntervalSince1970: Double(timestampInterval/1_000))
//                            let timestampStartDateFormatted = timestampFormatter.string(from: startIntervalDate).convertStringToInt()
                            
                            /* previous code to return one month averaged temperature values
                             self.averageValueAndCountForInterval.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: temperature)
                             self.oneMonthSortedDictionary = self.averageValueAndCountForInterval.averageValue
 //                            print("sortedDictionary \(self.oneMonthSortedDictionary)")

                             */
                            
//                            self.averageValueAndCountForInterval.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: temperature)
//                            self.temperatureSortedDictionary = self.averageValueAndCountForInterval.averageValue
//                            self.averageValueAndCountForIntervalClass.averageValue = [:]
                            
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
//                                self.averageValueAndCountForInterval.averageValue = [:]
                            }
//                            self.averageValueAndCountForInterval.averageValue = [:]
//
                            self.timestampsFiltered1M = self.oneMonthSortedDictionary.keys.elements
                            self.temperatureFiltered1M = self.oneMonthSortedDictionary.values.elements
                        }
                    }
                
                /*

                if let data = snapshot.value as? [String: Any] {
                    if data.count == 5 {
                        let values = data.map({ ($0.value) })
                        let keys = data.map({ ($0.key) })

                        let temperature = values[keys.firstIndex(of: MockDataLog.CodingKeys.temperature.rawValue)!] as! Double
                        let timestamp = values[keys.firstIndex(of: MockDataLog.CodingKeys.timestamp.rawValue)!] as! Int
                        let tds = values[keys.firstIndex(of: MockDataLog.CodingKeys.totalDissolvedSolids.rawValue)!] as! Int
                        let turbidity = values[keys.firstIndex(of: MockDataLog.CodingKeys.turbidity.rawValue)!] as! Int
                        let waterlevel = values[keys.firstIndex(of: MockDataLog.CodingKeys.waterLevel.rawValue)!] as! Double

                        self.mockDataLog = [MockDataLog(temperature: temperature, timestamp: timestamp, totalDissolvedSolids: tds, turbidity: turbidity, waterLevel: waterlevel)]
    //    //                    print(self.mockDataLog)
    //                        dataCount += 1
    //                        print("dataCount in if statement \(dataCount)") // queried count checks out with if statement appended values

                        if timestamp > timestampInterval {
                            let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
                            let timestampFormatter = DateFormatter()
                                timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
                                timestampFormatter.locale = NSLocale.current
                                timestampFormatter.dateFormat = "dd" //Specify your format that you want
                            let timestampsFiltered = timestampFormatter.string(from: date).convertStringToInt()

                            self.oneMonthAverageValueAndCount.averageForEachDayOfMonth(for: timestampsFiltered, parameter: temperature)
                            self.oneMonthSortedDictionary = self.oneMonthAverageValueAndCount.averageValue
                            print("sortedDictionary \(self.oneMonthSortedDictionary)")
                        }
                    }
                }
                
                */ // commented out if let statements to try guard let and do/catch
            } // databaseHandle
        }
    } // func
    
    /* // commented out for test
     
    func returnFirebaseDataThreeMonth(for interval: Int) { // equals the other one so querying helps reduce amount of data we need to fetch
        print("Returning Three Month Firebase Data...")
        
        let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
        let timestampInterval = currentUnixTimestampLong - interval
        let mockDataLogRef = Database.database().reference(withPath: "Mock Data Log")
        
        databaseHandle = mockDataLogRef.queryOrdered(byChild: "Timestamp").queryStarting(afterValue: timestampInterval).observe(.childAdded) { (snapshot) in
            
            guard let data = snapshot.value as? [String: Any] else { return }
                if data.count == 5 {
                    let values = data.map({ ($0.value) })
                    let keys = data.map({ ($0.key) })
                    
                    let temperature = values[keys.firstIndex(of: MockDataLog.CodingKeys.temperature.rawValue)!] as! Double
                    let timestamp = values[keys.firstIndex(of: MockDataLog.CodingKeys.timestamp.rawValue)!] as! Int
//                    let tds = values[keys.firstIndex(of: MockDataLog.CodingKeys.totalDissolvedSolids.rawValue)!] as! Int
//                    let turbidity = values[keys.firstIndex(of: MockDataLog.CodingKeys.turbidity.rawValue)!] as! Int
//                    let waterlevel = values[keys.firstIndex(of: MockDataLog.CodingKeys.waterLevel.rawValue)!] as! Double

//                    self.mockDataLog = [MockDataLog(temperature: temperature, timestamp: timestamp, totalDissolvedSolids: tds, turbidity: turbidity, waterLevel: waterlevel)]
                    if timestamp > timestampInterval {
                        let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
                        let timestampFormatter = DateFormatter()
                            timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
                            timestampFormatter.locale = NSLocale.current
                            timestampFormatter.dateFormat = "Mdd" //Specify your format that you want
                        let timestampsFiltered = timestampFormatter.string(from: date).convertStringToInt()
                        
                        self.averageValueAndCountForInterval.averageForEachDateFormatterKey(for: timestampsFiltered, parameter: temperature)
                        self.threeMonthSortedDictionary = self.averageValueAndCountForInterval.averageValue
//                            print("sortedDictionary3M \(self.threeMonthSortedDictionary)")
                        self.timestampsFiltered3M = self.threeMonthSortedDictionary.keys.elements
                        self.temperatureFiltered3M = self.threeMonthSortedDictionary.values.elements
                    }
                }
            
           
        } // databaseHandle
    } // func
     */
}
