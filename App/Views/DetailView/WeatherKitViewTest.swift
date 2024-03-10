//
//  WeatherKitViewTest.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 7/7/22.
//

import Foundation
import SwiftUI
import WeatherKit
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    
    @Published var currentLocation: CLLocation?
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last, currentLocation == nil else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
}

extension Date {
    func formatAsAbbreviatedDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
//        formatter.dateFormat = "MM/dd"
        return formatter.string(from: self)
    }
    func formatAsAbbreviatedTime(timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        formatter.timeZone = TimeZone(abbreviation: timezone)
        return formatter.string(from: self)
    }
}

struct HourlyForcastViewModel: View {
    
    let hourWeatherList: [HourWeather]
    
    var body: some View {
        ZStack (alignment: .center) {
            if hourWeatherList.isEmpty {
                HStack(alignment: .center) {
                    Spacer()
                    VStack(alignment: .center) {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack (alignment: .top, spacing: 25) {
                        VStack {
                            Spacer()
                            if hourWeatherList.first?.symbolName == "cloud" {
                                Text("Now").font(.system(size: 16, weight: .medium)).padding(.bottom, 4.0)
                            } else {
                                Text("Now").font(.system(size: 16, weight: .medium))
                            }
                            Spacer()
                            Image(systemName: "\(hourWeatherList.first?.symbolName ?? "exclamationmark.triangle").fill")
                                .symbolRenderingMode(.multicolor)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\((hourWeatherList.first?.temperature.converted(to: .fahrenheit).value)!, specifier: "%.0f")\u{00B0}F")
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                        }
                    
                        ForEach(hourWeatherList, id: \.date) { hourWeatherItem in
                            VStack {
                                Spacer()
                                if hourWeatherItem.symbolName == "cloud" {
                                    Text(hourWeatherItem.date.formatAsAbbreviatedTime(timezone: "EST")).font(.system(size: 16, weight: .medium)).padding(.bottom, 4.0)
                                } else {
                                    Text(hourWeatherItem.date.formatAsAbbreviatedTime(timezone: "EST")).font(.system(size: 16, weight: .medium))
                                }
                                Spacer()
                                if hourWeatherItem.symbolName != "wind" {
                                    Image(systemName: "\(hourWeatherItem.symbolName).fill")
                                        .symbolRenderingMode(.multicolor)
                                        .foregroundColor(.gray)
                                }
                                else {
                                    Image(systemName: "\(hourWeatherItem.symbolName)")
                                        .symbolRenderingMode(.multicolor)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("\(hourWeatherItem.temperature.converted(to: .fahrenheit).value, specifier: "%.0f")\u{00B0}F")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                        }
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct HourlyForecastView: View {
    //FIXME: REMOVE POND LOCATION
    let pondLocation: CLLocation = CLLocation(latitude: 30.26426, longitude: -97.74750) // coordinates have been changed to keep pond location undisclosed
    let weatherService = WeatherService.shared
    @StateObject private var locationManager = LocationManager()
    @State private var weather: Weather?
    
    var hourlyWeatherData: [HourWeather] {
        if let weather {
            return Array(weather.hourlyForecast.filter { hourlyWeather in
                return hourlyWeather.date.timeIntervalSince(Date()) >= 0
            }.prefix(24))
        } else {
            return []
        }
    }
    
    var body: some View {
        VStack {
            HourlyForcastViewModel(hourWeatherList: hourlyWeatherData)
        }
        .task {
            do {
                let pondLocation: CLLocation = CLLocation(latitude: 30.26426, longitude: -97.74750) // coordinates have been changed to keep pond location undisclosed
                self.weather = try await weatherService.weather(for: pondLocation)
//                print(weather as Any)
                print("Returned Hourly Weather Data For The Next 24 Hours.")
            } catch {
                print(error)
            }
        }
    }
}

struct HourlyForecastView_Previews: PreviewProvider {
    static var previews: some View {
        HourlyForecastView().frame(height: 150).padding()
            .previewLayout(.sizeThatFits)
    }
}
struct DailyWeatherView_Previews: PreviewProvider {
    static var previews: some View {
        DailyWeatherView()
    }
}

struct DailyWeatherViewRainfall_Previews: PreviewProvider {
    static var previews: some View {
        DailyWeatherView2()
    }
}

// FIXME: Today forecast shows tomorrows
struct DailyWeatherViewModel: View {
    @Environment(\.colorScheme) var colorScheme
    var dailyWeatherList: [DayWeather]
//    let currentWeatherList: CurrentWeather
    
    var totalRainfall: [Double] {
        if !dailyWeatherList.isEmpty {
            return dailyWeatherList.map({ dayWeather in
                let totalRainfall = round(dayWeather.rainfallAmount.converted(to: .inches).value * 10000)/10000.0 // rounded and multiplied/divided to round to thousandths place.
                return totalRainfall
            })
        } else {
            return []
        }
    }
    
    var weeklyTempHigh: Double {
        if !dailyWeatherList.isEmpty {
            return dailyWeatherList.map({ dayWeather in
                let weeklyTempHigh = dayWeather.highTemperature.converted(to: .fahrenheit).value
                return weeklyTempHigh
            }).max()!
        } else {
            return 0
        }
    }
    
    var weeklyTempLow: Double {
        if !dailyWeatherList.isEmpty {
            return dailyWeatherList.map({ dayWeather in
                let weeklyTempLow = dayWeather.lowTemperature.converted(to: .fahrenheit).value
                return weeklyTempLow
            }).min()!
        } else {
            return 0
        }
    }
    
    var currentTemperature: Double
//    let gradient = LinearGradient(colors: [.green, .yellow, .orange, .red], startPoint: .bottom, endPoint: .top)
    let gradient = Gradient(colors: [.green, .yellow, .orange, .red])
    
    let gaugeFrame: CGFloat = 90
    
    var body: some View {
        ZStack (alignment: .center) {
            if dailyWeatherList.isEmpty {
                HStack {
                    Spacer()
                    ProgressView().offset(y:-100)
                    Spacer()
                }
                
            } else {
                ScrollView() {
                    VStack (alignment: .leading, spacing: 8) {
                        HStack (spacing: 20) {
                            Text("Today").font(.system(size: 16, weight: .medium)).frame(alignment: .leading).frame(width:45, alignment: .leading)
                            Image(systemName: "\(dailyWeatherList.first?.symbolName ?? "exclamationmark.triangle").fill").symbolRenderingMode(.multicolor)
                                .foregroundColor(.gray).frame(width:25.0)
                            Text("\((dailyWeatherList.first?.lowTemperature.converted(to: .fahrenheit).value)!, specifier: "%.0f")\u{00B0}F")
                                .font(.system(size: 16, weight: .medium)).frame(width:40.0)
                            if !dailyWeatherList.isEmpty {
                                ZStack (alignment:.center){
                                    Gauge(value: weeklyTempLow, in: weeklyTempLow...weeklyTempHigh) {
                                    }.gaugeStyle(.accessoryLinearCapacity)
                                        .frame(width:gaugeFrame)
                                        .overlay(alignment: .leading) {
                                            let lowTempDiff = (dailyWeatherList.first?.lowTemperature.converted(to: .fahrenheit).value)! - weeklyTempLow
                                            let highTempDiff = weeklyTempHigh - (dailyWeatherList.first?.highTemperature.converted(to: .fahrenheit).value)!
                                            let temperatureIncrementOffsetShift = gaugeFrame/(weeklyTempHigh-weeklyTempLow)
                                            Gauge(value: (dailyWeatherList.first?.highTemperature.converted(to: .fahrenheit).value)!, in: (dailyWeatherList.first?.lowTemperature.converted(to: .fahrenheit).value)!...(dailyWeatherList.first?.highTemperature.converted(to: .fahrenheit).value)!) {
                                            }.gaugeStyle(.accessoryLinearCapacity).tint(Color.secondary.opacity(0.5))
                                                .offset(x: ((dailyWeatherList.first?.lowTemperature.converted(to: .fahrenheit).value)!-weeklyTempLow)*temperatureIncrementOffsetShift).frame(width: (gaugeFrame - ((lowTempDiff + highTempDiff) * temperatureIncrementOffsetShift)))
                                        }
                                }
                            }
                            Text("\((dailyWeatherList.first?.highTemperature.converted(to: .fahrenheit).value)!, specifier: "%.0f")\u{00B0}F")
                                .font(.system(size: 16, weight: .medium))
                        }
                        Divider().background(Color.secondary).padding(.horizontal, 3.0)
                        //                .frame(width: .infinity, alignment: .leading)
                        
                        ForEach(dailyWeatherList, id: \.date) { dailyWeather in
                            HStack (spacing: 20) {
                                Text(dailyWeather.date.formatAsAbbreviatedDay()).font(.system(size: 16, weight: .medium)).frame(width: 45.0, alignment: .leading)
                                if dailyWeather.symbolName != "wind" {
                                    Image(systemName: "\(dailyWeather.symbolName).fill")
                                        .symbolRenderingMode(.multicolor)
                                    //                                .foregroundColor(.gray)
                                        .frame(width:25.0)
                                }
                                else {
                                    Image(systemName: "\(dailyWeather.symbolName)")
                                        .symbolRenderingMode(.multicolor)
                                        .foregroundColor(.gray).frame(width:25.0)
                                }
                                Text("\((dailyWeather.lowTemperature.converted(to: .fahrenheit).value), specifier: "%.0f")\u{00B0}F")
                                    .font(.system(size: 16, weight: .medium)).frame(width:40.0)
                                
                                ZStack (alignment:.center){
                                    Gauge(value: weeklyTempLow, in: weeklyTempLow...weeklyTempHigh) {
                                    }.gaugeStyle(.accessoryLinearCapacity)
                                        .frame(width:gaugeFrame)
                                        .overlay(alignment: .leading) {
                                            let lowTempDiff = (dailyWeather.lowTemperature.converted(to: .fahrenheit).value) - weeklyTempLow
                                            let highTempDiff = weeklyTempHigh - (dailyWeather.highTemperature.converted(to: .fahrenheit).value)
                                            let temperatureIncrementOffsetShift = gaugeFrame/(weeklyTempHigh-weeklyTempLow)
                                            Gauge(value: (dailyWeather.highTemperature.converted(to: .fahrenheit).value), in: (dailyWeather.lowTemperature.converted(to: .fahrenheit).value)...(dailyWeather.highTemperature.converted(to: .fahrenheit).value)) {
                                            }.gaugeStyle(.accessoryLinearCapacity).tint(Color.secondary.opacity(0.5))
                                                .offset(x: ((dailyWeather.lowTemperature.converted(to: .fahrenheit).value)-weeklyTempLow)*temperatureIncrementOffsetShift).frame(width: (gaugeFrame - ((lowTempDiff + highTempDiff) * temperatureIncrementOffsetShift)))
                                        }
                                }
                                Text("\((dailyWeather.highTemperature.converted(to: .fahrenheit).value), specifier: "%.0f")\u{00B0}F")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            //                    .frame(width: .infinity, alignment: .leading)
                            Divider().background(Color.secondary).padding(.horizontal, 3.0)
                        }
                        ZStack {
                            Rectangle().frame(height: 1).foregroundColor(colorScheme == .light ? Color.white : Color.black).offset(y:-9)//.frame(width: .infinity, height: 1)
                            Rectangle().frame(height: 1).foregroundColor(Color.secondary.opacity(0.3)).offset(y:-9)//.frame(width: .infinity, height: 1)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                .foregroundColor(.secondary)
            }
        }
    }
}

struct DailyWeatherView: View {
    
    let weatherService = WeatherService.shared
    @State private var weather: Weather?
    
    var dailyWeatherData: [DayWeather] {
        if let weather {
            return Array(weather.dailyForecast.filter { dailyWeather in
                return dailyWeather.date.timeIntervalSince(Date()) >= 0
            }.prefix(7))
        } else {
            return []
        }
    }
    var currentTemperature: Double {
        if let weather {
            return weather.currentWeather.temperature.value
        } else {
            return 0.0
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                DailyWeatherViewModel(dailyWeatherList: dailyWeatherData, currentTemperature: currentTemperature)
            }
            .task {
                do {
                    let pondLocation: CLLocation = CLLocation(latitude: 30.26426, longitude: -97.74750) // coordinates have been changed to keep pond location undisclosed
                    self.weather = try await weatherService.weather(for: pondLocation)
//                    print(weather as Any)
                    print("Returned Daily Weather Data For The Week.")
                } catch {
                    print(error)
                }
            }
        }
    }
}

struct DailyWeatherViewModel2: View {
    var dailyWeatherList: [DayWeather]
    
    var dailyRainfall: [Double] {
        if !dailyWeatherList.isEmpty {
            return dailyWeatherList.map({ dayWeather in
                let totalRainfall = round(dayWeather.rainfallAmount.converted(to: .inches).value * 1000)/1000.0 // rounded and multiplied/divided to round to thousandths place.
                return totalRainfall
            })
        } else {
            return []
        }
    }
    func totalRainfall(dailyRainfallArray: [Double]) -> Double {
            dailyRainfallArray.reduce(0, +)
    }
    
    var body: some View {
        VStack {
            if !dailyRainfall.isEmpty {
                HStack (alignment: .center) {
                    Text("\(dailyRainfall[0], specifier: "%.2f")\"")
                        .fontWeight(.medium)
                    Text("expected today (\(dailyWeatherList[0].precipitationChance*100, specifier: "%.0f")%)")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 5)
                }
                HStack (alignment: .center){
                    Text("\(totalRainfall(dailyRainfallArray:dailyRainfall), specifier: "%.2f")\"").fontWeight(.medium)
                    Text("expected in the next 72 hours.")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}

struct DailyWeatherView2: View {
    
    let weatherService = WeatherService.shared
    @State private var weather: Weather?
    
    var dailyWeatherData: [DayWeather] {
        if let weather {
            return Array(weather.dailyForecast.filter { dailyWeather in
                return dailyWeather.date.timeIntervalSince(Date()) >= 0
            }.prefix(3))
        } else {
            return []
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                DailyWeatherViewModel2(dailyWeatherList: dailyWeatherData)
            }
            .task {
                do {
                    let pondLocation: CLLocation = CLLocation(latitude: 30.26426, longitude: -97.74750) // coordinates have been changed to keep pond location undisclosed
                    self.weather = try await weatherService.weather(for: pondLocation)
                    print("Returned Weather Rainfall Data For The Next 72 Hours.")
//                    print(weather as Any)
                } catch {
                    print(error)
                }
            }
        }
    }
}

struct CurrentWeatherViewModel: View {
    let currentWeatherList: CurrentWeather
    let weatherService = WeatherService.shared
    
    var body: some View {
        Text("\(currentWeatherList.uvIndex.value)")
    }
}

struct CurrentWeatherView: View {
    
    let weatherService = WeatherService.shared
    @State private var weather: CurrentWeather?
    
    var body: some View {
        VStack {
            if let weather {
                HStack {
                    Text("UV Index: ")
                    Text("\(weather.uvIndex.value)")
                }
            }
        }
        .task {
            do {
                //FIXME: REMOVE POND LOCATION BEFORE UPLOADING
                let pondLocation: CLLocation = CLLocation(latitude: 30.26426, longitude: -97.74750) // coordinates have been changed to keep pond location undisclosed
                self.weather = try await weatherService.weather(for: pondLocation, including: .current)
//                print(weather as Any)
                print("Returned Current Weather Data.")
            } catch {
                print(error)
            }
        }
    }
}
