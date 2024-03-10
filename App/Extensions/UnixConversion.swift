//
//  UnixConversion.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/10/22.
//

import Foundation

extension Int {
    func convertIntToTimestamp(dateformat: String) -> String {
        let date = Date(timeIntervalSince1970: Double(self))
        let timestampFormatter = DateFormatter()
            timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
            timestampFormatter.locale = NSLocale.current
            timestampFormatter.dateFormat = dateformat
        return timestampFormatter.string(from: date)
    }
    func convertIntLongToTimestamp(dateformat: String) -> String {
        let date = Date(timeIntervalSince1970: Double(self/1_000))
        let timestampFormatter = DateFormatter()
        timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
        timestampFormatter.locale = NSLocale.current
        timestampFormatter.dateFormat = dateformat
//        timestampFormatter.dateFormat = "MM/dd h:mm a"
        return timestampFormatter.string(from: date)
    }
}

extension String {
    
    func convertStringToInt() -> Int {
        return Int(Double(self) ?? 0.0)
    }
    
    func convertStringToDouble() -> Double {
        return Double(self) ?? 0.0
//        return NumberFormatter().number(from: self)?.doubleValue
    }
    
    func convertStringToTimestamp(dateformat: String) -> String {
        let date = Date(timeIntervalSince1970: Double(self) ?? 0.0)
        let timestampFormatter = DateFormatter()
        timestampFormatter.timeZone = TimeZone(abbreviation: "EST") //Set timezone that you want
        timestampFormatter.locale = NSLocale.current
        timestampFormatter.dateFormat = dateformat
//        timestampFormatter.dateFormat = "MM/dd h:mm a"
        return timestampFormatter.string(from: date)
    }
    
    func createDateTime() -> (strDay: String, strDate: String) {
        var strDate = ""
        var strDay = ""
            
        if let unixTime = Double(self) {
            let date = Date(timeIntervalSince1970: unixTime)
            let dateFormatter = DateFormatter()
            let timezone = TimeZone.current.abbreviation() ?? "EST"  // get current TimeZone abbreviation or set to CET
            dateFormatter.timeZone = TimeZone(abbreviation: timezone) //Set timezone that you want
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "MM/d @ HH:mma" //Specify your format that you want (i.e. "MM/dd/yyyy HH:mm a")
            strDate = dateFormatter.string(from: date)
            
            if Calendar.current.isDateInToday(date) {
                strDay = "Today"
                //return strDay
            } else if Calendar.current.isDateInYesterday(date) {
                strDay = "Yesterday"
                //return strDay
            }
        }
            
        return (strDay, strDate)
    }
}

func inchesToFeetInches(_ value: Double) -> String {
  let formatter = MeasurementFormatter()
  formatter.unitOptions = .providedUnit
  formatter.unitStyle = .short

  let rounded = value.rounded(.towardZero)
  let feet = Measurement(value: rounded, unit: UnitLength.feet)
  let inches = Measurement(value: value - rounded, unit: UnitLength.feet).converted(to: .inches)
  return ("\(formatter.string(from: feet)) \(formatter.string(from: inches))")
}
