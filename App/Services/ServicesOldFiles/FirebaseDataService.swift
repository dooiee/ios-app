//
//  FirebaseDataService.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/10/22.
//

import Foundation
import Firebase
import Combine
import FirebaseSharedSwift
import SwiftUI


//FIXME: App still relies on this file so still need it

struct TimeIntervalAverageValueAndCount {
    var averageValue: [Int: Double] = [:]
    var dataCount: [Int: Int] = [:]
    
    mutating func averageForEachDay(for timestampFormatterDay: Int, parameter: Double) {
        if averageValue[timestampFormatterDay] == nil {
            dataCount[timestampFormatterDay] = 1
            averageValue[timestampFormatterDay] = parameter
//            print("if: \(averageValue)")
        } else {
            guard let meanNMinusOne = averageValue.removeValue(forKey: timestampFormatterDay) else { return }
            guard var dataCountPerDay = dataCount.removeValue(forKey: timestampFormatterDay) else { return }
            dataCountPerDay += 1
            let updatedMean = meanNMinusOne + ((parameter - meanNMinusOne)/Double(dataCountPerDay))
//            print("\(updatedMean) = \(meanNMinusOne) + (\(parameter) - \(meanNMinusOne)) / \(Double(dataCountPerDay))") // working print to make sure all parts of equation are being retreived correctly.
            dataCount.updateValue(dataCountPerDay, forKey: timestampFormatterDay)
            averageValue.updateValue(updatedMean, forKey: timestampFormatterDay)
//            print("mean(n): \(averageValue)")
//            print("dataCountVar \(dataCount)") // this print displays the total counted values for each day. i.e. (dataCountVar [12: 2742, 17: 2736, 31: 2664, ... ]
        }
    }
}

class FirebaseDataService: ObservableObject {
    
    @Published var allData: [FirebaseModel] = []
    @Published var intervalLog5Min: [IntervalLog5Min] = []
    @Published var allDataTest4 = [IntervalLog5Min]()
    @Published var mockDataLog = [MockDataLog]()
    @Published var mockDataLog2 = [MockDataLog]()
    @Published var pondParameters = [PondParameters]()
    
    @Published var allDataTempValues: [String] = []
    @Published var allDataTimestampValues: [String] = []
    @Published var allDataTempValuesDouble: [Double] = []
    
    @Published var timestampsFiltered1D: [Int] = []
    @Published var temperatureFiltered1D: [Double] = []
    @Published var isFiveOrTenCounter: [Int] = []
    @Published var timestampsFiltered1W: [Int] = []
    @Published var temperatureFiltered1W: [Double] = []
    @Published var isOneHourCounter: [Int] = []
    
    @Published var timestamps1H: [Int] = []
    @Published var timestamps1D: [Int] = []
    @Published var timestamps1W: [Int] = []
    @Published var timestamps1M: [Int] = []
    @Published var timestamps3M: [Int] = []
    @Published var timestamps1Y: [Int] = []
    @Published var timestampsAll: [Int] = []
    
    @Published var temperature1H: [Double] = []
    @Published var temperature1D: [Double] = []
    @Published var temperature1W: [Double] = []
    @Published var temperature1M: [Double] = []
    @Published var temperature3M: [Double] = []
    @Published var temperature1Y: [Double] = []
    @Published var temperatureAll: [Double] = []
    
    init() {}
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
    var eachDayAverageValueAndCount = TimeIntervalAverageValueAndCount()

    func getAverage(for data: [Double]) -> Double {
        data.reduce(0, +) / Double(data.count)
    }
    
    func returnFirebaseDataOneMonth(for interval: Int) { // equals the other one so querying helps reduce amount of data we need to fetch
        
        let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
        let timestampInterval = currentUnixTimestampLong - interval
        let sensorDataLogRef = Database.database().reference(withPath: "Sensor Data Log")
        
        databaseHandle = sensorDataLogRef.queryOrdered(byChild: "Timestamp").queryStarting(afterValue: timestampInterval).observe(.childAdded) { (snapshot) in

            if let data = snapshot.value as? [String: Any] {
                if data.count == 6 {
                    let values = data.map({ ($0.value) })
                    let keys = data.map({ ($0.key) })
                    
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
                            timestampFormatter.dateFormat = "dd" //Specify your format that you want
                        let timestampsFiltered = timestampFormatter.string(from: date).convertStringToInt()
                        self.eachDayAverageValueAndCount.averageForEachDay(for: timestampsFiltered, parameter: temperature)
                    }
                }
            }
        } // databaseHandle
    } // func
    
    func getFirebaseData() {
        
        print("Retreiving Firebase Data...")
        
        let ref = Database.database().reference()

//        let currentUnixTimestamp = Int(Date().timeIntervalSince1970) // 1648268218
        //print(currentUnixTimestamp)
        let currentUnixTimestampLong = Int(Date().timeIntervalSince1970*1_000) // 1648268218661
        let lastHourUnixTimestampLong = currentUnixTimestampLong - 1_000*60*60
        let lastDayUnixTimestampLong = currentUnixTimestampLong - 1_000*60*60*24 // 1648248289020
//        let lastWeekUnixTimestamp = Int(Date().timeIntervalSince1970) - 60*60*24*7 // 1647643416
        let lastWeekUnixTimestampLong = currentUnixTimestampLong - 1_000*60*60*24*7 // 1648247770620
        let lastMonthUnixTimestampLong = currentUnixTimestampLong - 1_000*60*60*24*30
        let lastThreeMonthsUnixTimestampLong = currentUnixTimestampLong - 1_000*60*60*24*90
//        let lastSixMonthsUnixTimestampLong = currentUnixTimestampLong - 1_000*60*60*24*180
        let lastYearUnixTimestampLong = currentUnixTimestampLong - 1_000*60*60*24*365
        let allTimeUnixTimestampLong = currentUnixTimestampLong - Int(Date().timeIntervalSinceReferenceDate*1_000)
        
        /////////// Date Formatter (Double to String)
//        let lastWeekDateConversion = Date(timeIntervalSince1970: Double(lastWeekUnixTimestampLong/1_000))
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "MM/dd/yyyy hh:mma" //Specify your format that you want
//        let lastWeekDateConversionstrDate = dateFormatter.string(from: lastWeekDateConversion)
        //print("Date one week ago: \(lastWeekDateConversionstrDate)")
        var count = 0
        var count1W = 0
        var timestampAtZero: Bool = false
        
        //MARK: Comment out for now
//        let lastMonthInterval: Int = 1_000*60*60*24*30
//        returnFirebaseData(for: lastMonthInterval)
        
        databaseHandle = ref.child("Sensor Data Log").observe(.childAdded) { (snapshot) in
          // prints similar to DataSnapshot Marked above
            if let datas = snapshot.value as? [String : Any] {
                //print(datas.count)
                if (datas.count == 6) { // datas.count used to only grab data entries where all parameters exist (basically filtered out incomplete entries)
                    let values = datas.map({ ($0.value) })
                    let keys = datas.map({ ($0.key) })
//                    self.allDataTempValuesDouble.append(values[keys.firstIndex(of: "Temperature")!] as! Double)
                    //print("\(self.allDataTempValuesDouble.count)")
                    let temperature = values[keys.firstIndex(of: MockDataLog.CodingKeys.temperature.rawValue)!] as! Double
                    let timestamp = values[keys.firstIndex(of: MockDataLog.CodingKeys.timestamp.rawValue)!] as! Int
                    let tds = values[keys.firstIndex(of: MockDataLog.CodingKeys.totalDissolvedSolids.rawValue)!] as! Int
                    let turbidity = values[keys.firstIndex(of: MockDataLog.CodingKeys.turbidity.rawValue)!] as! Int
                    let waterlevel = values[keys.firstIndex(of: MockDataLog.CodingKeys.waterLevel.rawValue)!] as! Double
                    let ph = values[keys.firstIndex(of: MockDataLog.CodingKeys.pH.rawValue)!] as! Double
//                    self.mockDataLog2.append(MockDataLog(temperature: temperature, timestamp: timestamp, totalDissolvedSolids: tds, turbidity: turbidity, waterLevel: waterlevel))
//                    print("self.mockDataLog2 \(self.mockDataLog2)")
                    self.mockDataLog = [MockDataLog(temperature: temperature, timestamp: timestamp, totalDissolvedSolids: tds, turbidity: turbidity, waterLevel: waterlevel, pH: ph)]
//                    print(self.mockDataLog)
                    
                    //MARK: Filtering child timestamps to retrieve each interval to plot
                    // maybe add while count not equal to final length of array (done through .value not childAdded), we do not append yet
                    //MARK: 1H
                    if timestamp > lastHourUnixTimestampLong {
//                        let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
//                        let dateFormatter = DateFormatter()
//                        dateFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
//                        dateFormatter.locale = NSLocale.current
//                        dateFormatter.dateFormat = "MM/dd/yyyy hh:mma" //Specify your format that you want
//                        let lastWeekDateConversionstrDate = dateFormatter.string(from: lastWeekDateConversion)
//                        let lastWeekDateConversion = Date(timeIntervalSince1970: Double(lastWeekUnixTimestampLong/1_000))
                        self.timestamps1H.append(timestamp)
                        self.temperature1H.append(temperature)
     
//                        print("returned values: \(self.filteredTimestamps.count), timestamp: \(strDate), \(self.filteredTimestamps.last ?? 0) > \(lastWeekUnixTimestampLong)")
//                        print("returned values: \(self.timestamps1H.count), timestamp: \(strDate), temperature: \(self.temperature1H)")
                    }
                    //MARK: 1D // Appears to be working with print statements so commenting out the following below
                    /*
                     10 timestampsFiltered
                     timestampsFiltered1DCount 267
                     isFiveTenCounterArray [-1, 1]
                     timestampsFiltered1D: [1648703426433, 1648703719726]
                     temperatureFiltered1D: [73.85, 73.5125]
                     */
                    
                    //TODO: 1D // now want to ensure value are being removed when they go beyond the 24 hour period
                    if timestamp > lastDayUnixTimestampLong {
//                        let lastTimestamp = timestamp1D
                        let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
                        let timestampFormatter = DateFormatter()
                            timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
                            timestampFormatter.locale = NSLocale.current
                            timestampFormatter.dateFormat = "mm" //Specify your format that you want
                        let timestampsFiltered = timestampFormatter.string(from: date).convertStringToInt()
                        
//                        print(timestampsFiltered)
                        // if count is > 5 in between entering if statement then that means arduino did not capture the last 5 minute interval so we should append same temperature value and append timestamp shifted by 5 minutes (timestamp + 1_000*60*5). the count actually works to make sure there are not two measurements on the 5 minute mark
                        if timestampsFiltered % 5 == 0 && count > 1 {
                            /*
                             Setting a variable here that count +1 everytime the filtered timestamp is divisible by 5 and counts -1 everytime the filtered timestamp is divisible by 10. If the number gets to +2 or -2 that means the arduino has missed a 5 minute interval value and has gone 10 minutes before recording the value. Thus we will append/carry over the last temperature value recorded 10 minutes prior and we will append an adjusted timestamp that is 5 minutes prior to our array.
                             */
                            let isFiveOrTenCounterLocal = timestampsFiltered % 2 == 0 ? -1 : 1
//                            print("is5or10counter = \(isFiveOrTenCounter)")
                            
                            if self.isFiveOrTenCounter.count < 2 {
                                self.isFiveOrTenCounter.append(isFiveOrTenCounterLocal)
//                                print("isFiveTenCounterArray \(self.isFiveOrTenCounter)")
                            } else {
                                self.isFiveOrTenCounter.removeFirst()
                                self.isFiveOrTenCounter.append(isFiveOrTenCounterLocal)
//                                print("isFiveTenCounterArray \(self.isFiveOrTenCounter)")
                            }
                            
                            if self.isFiveOrTenCounter.reduce(0, +) == 2 || self.isFiveOrTenCounter.reduce(0, +) == -2 {
//                                print("Arduino has missed a 5 or 10 minute interval value!!")
//                                print("array total: \(self.isFiveOrTenCounter[0] + self.isFiveOrTenCounter[1])")
                                self.timestampsFiltered1D.append(timestamp - 1_000*60*5) // artificially adds in the missing timestamp
//                                print("timestampsFiltered1D: \(self.timestampsFiltered1D.suffix(2))")
                                let lastTemperature = self.temperature1D.last ?? 0.0
                                self.temperatureFiltered1D.append(lastTemperature)
//                                print("temperatureFiltered1D: \(self.temperatureFiltered1D.suffix(2))")
//                                print("\(Int(timestampsFiltered) - 5) timestampsFiltered ADDED***")

                            }
                            
//                            self.timestampsFiltered1D.append(self.isFiveOrTenCounter.reduce(0, +) == 2 || self.isFiveOrTenCounter.reduce(0, +) == -2 ? timestamp - 1_000*60*5 : timestamp)
//                            print("timestampsFiltered1D: \(self.timestampsFiltered1D.suffix(2))")
//                            let lastTemperature = self.temperature1D.last ?? 0.0
//                            self.temperatureFiltered1D.append(self.isFiveOrTenCounter.reduce(0, +) == 2 || self.isFiveOrTenCounter.reduce(0, +) == -2 ? lastTemperature : temperature)
                            
                            self.timestampsFiltered1D.append(timestamp)
//                            print("timestampsFiltered1D: \(self.timestampsFiltered1D.suffix(2))")
                            self.temperatureFiltered1D.append(temperature)
//                            print("temperatureFiltered1D: \(self.temperatureFiltered1D.suffix(2))")
                            
//                            print("\(Int(timestampsFiltered)) timestampsFiltered")
                            
                            
//                            print("timestampsFiltered1D \(self.timestampsFiltered1D.suffix(2))")
//                            print("timestampsFiltered1DCount \(self.timestampsFiltered1D.count)")
                            count = 0
                        }
                        else {
                            count += 1
                        }
                        
                        //print("\(count) count")
                        
                        self.timestamps1D.append(timestamp)
//                        print("timestamps1DCount \(self.timestamps1D.count)")
                        self.temperature1D.append(temperature)
                        
                    }
                    //MARK: 1W // messsy but all edge cases are taken care of and values are filtered every hour and appended
                    if timestamp > lastWeekUnixTimestampLong {
                        let date = Date(timeIntervalSince1970: Double(timestamp/1_000))
                        let timestampFormatter = DateFormatter()
                            timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
                            timestampFormatter.locale = NSLocale.current
                            timestampFormatter.dateFormat = "mm" //Specify your format that you want
                        let timestampsFiltered = timestampFormatter.string(from: date).convertStringToInt()
//                        print(timestampsFiltered)
//                        print("outside if statement \(timestampAtZero)")
//                        print("count1W \(count1W)")
                        if timestampsFiltered == 0 && count1W > 1 { // if statement tells us if we observed a 0, if we then observe a one then we toggle back identifying we will wait till the next 0, but if we get to 1 and the 0 is not observed then we will backtrack and add in the values for 0 before we append 1.
                            /// another way to do it could be to verify that the timestamp between 0 is not greater than an hour (would be close to 2 if it missed a 0)
//                            print(timestampsFiltered)
//                            print("\(timestampsFiltered) timestampsFiltered if")
                            timestampAtZero = true
//                            print("timestampAtZero inside == 0 loop: \(timestampAtZero)")
                            self.timestampsFiltered1W.append(timestamp)
//                            print("timestampsFiltered1W: \(self.timestampsFiltered1W.suffix(2))")
                            self.temperatureFiltered1W.append(temperature)
//                            print("temperatureFiltered1W: \(self.temperatureFiltered1W.suffix(2))")
                            count1W = 0
//                            print("timestampsFiltered1WCount \(self.temperatureFiltered1W.count)")
                        } else if timestampsFiltered <= 2 && timestampAtZero == true { // removes cases where 0 is observed twice and 1 is not observed. so we can still veify 0 was observed and we can toggle back.
                            // in this case a 0 was observed followed by a 1 so we can toggle back to false for next observation of 0. edge case is we could not observe a 1 so we do not reset. so we decide to explicitly make true for 0 identified and false when not observed or reset upon a 1 following.
                            timestampAtZero = false // change back to false to verify 0 was not skipped.
//                            print("else if loop: \(timestampAtZero)")
//                            print(timestampsFiltered)
//                            print("\(timestampsFiltered) timestampsFiltered else if true")
                            count1W += 1
                        } else if timestampsFiltered == 1 && timestampAtZero == false && count1W > 1 {
                            // here is where we observe a one but we have not observed a 0
//                            print("\(timestampsFiltered) timestampsFiltered else if false")
//                            print("\(Int(timestampsFiltered) - 1) timestampsFiltered ADDED***")
                            self.timestampsFiltered1W.append(timestamp - 1_000*60*1) // artificially adds in the missing timestamp ** only need to be 1 minute and not 60
//                            print("timestampsFiltered1W: \(self.timestampsFiltered1W.suffix(2))")
                            let lastTemperature = self.temperature1W.last ?? 0.0 // in this case, rather than carrying over the last value, decided to just take the value at the 1 minute mark.
                            self.temperatureFiltered1W.append(lastTemperature)
//                            print("temperatureFiltered1W: \(self.temperatureFiltered1W.suffix(2))")
//                            print("timestampsFiltered1WCount \(self.temperatureFiltered1W.count)")
//                            print(timestampsFiltered)
                            count1W = 1
                        }
                        else {
//                            print(timestampsFiltered)
                            count1W += 1
                        }
//                        print(timestampsFiltered)
                        self.timestamps1W.append(timestamp)
//                        print("timestamps1WCount \(self.timestamps1W.count)") // ~ 8407 data points
                        self.temperature1W.append(temperature)
                    }
                    //MARK: 1M // values will be captured everyday
                    // So I have all values in last month. Then I could sort value by day. I could then average each day's value. Then append those 30 average values to the array.
                    if timestamp > lastMonthUnixTimestampLong {
                        self.timestamps1M.append(timestamp)
                        self.temperature1M.append(temperature)
                    }                    
                    //MARK: 3M
                    if timestamp > lastThreeMonthsUnixTimestampLong {
                        self.timestamps3M.append(timestamp)
                        self.temperature3M.append(temperature)
                    }
                    //MARK: 1Y
                    if timestamp > lastYearUnixTimestampLong {
                        self.timestamps1Y.append(timestamp)
                        self.temperature1Y.append(temperature)
                    }
                    //MARK: ALL
                    if timestamp > allTimeUnixTimestampLong {
                        self.timestampsAll.append(timestamp)
                        self.temperatureAll.append(temperature)
                    }
                }
            }
        } // databaseHandle
    } // func
    
    func getFirebaseMockDataLog() {

        let ref = Database.database().reference()
        
        databaseHandle = ref.child("Mock Data Log").observe(.value) { (snapshot) in

            if let value = snapshot.value as? [String : MockDataLog] {
                let temp = value["Temperature"]
                print("temp \(String(describing: temp))")
            }
        }
    } // func
} // class
