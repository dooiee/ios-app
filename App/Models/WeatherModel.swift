//
//  WeatherModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 7/7/22.
//

import Foundation
import WeatherKit

struct ForecastInfo {
    var date: Date
//    var condition: String
    var symbolName: String
    var temperature: Temperature
    var precipitation: String
    var precipitationChance: Double
    var windSpeed: Measurement<UnitSpeed>
    var rainfallAmount: Measurement<UnitLength>
    var snowfallAmount: Measurement<UnitLength>
    var uvIndex: Int
    
    var isDailyForecast: Bool {
        temperature.isDaily
    }
    
    var isHourlyForecast: Bool {
        !temperature.isDaily
    }
}

extension ForecastInfo {
    init(_ forecast: DayWeather) {
        date = forecast.date
//        condition = forecast.condition.description
        symbolName = forecast.symbolName
        temperature = .daily(
            high: forecast.highTemperature,
            low: forecast.lowTemperature)
        precipitation = forecast.precipitation.description
        precipitationChance = forecast.precipitationChance
        windSpeed = forecast.wind.speed
        rainfallAmount = forecast.rainfallAmount
        snowfallAmount = forecast.snowfallAmount
        uvIndex = forecast.uvIndex.value
    }
}

extension ForecastInfo {
    enum Temperature {
        typealias Value = Measurement<UnitTemperature>
        
        case daily(high: Value, low: Value)
        case hourly(Value)
        
        var isDaily: Bool {
            switch self {
            case .daily:
                return true
            case .hourly:
                return false
            }
        }
    }
}

extension ForecastInfo.Temperature: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case let .daily(high, low):
            hasher.combine(0)
            hasher.combine(high)
            hasher.combine(low)
        case let .hourly(temp):
            hasher.combine(1)
            hasher.combine(temp)
        }
    }
}

struct CurrentWeatherInfo: Identifiable, Hashable {
    var code: String
    var date: Date
//    var condition: String
    var symbolName: String
    var temperature: Measurement<UnitTemperature>
    var windSpeed: Measurement<UnitSpeed>
    var uvIndex: Int
    var humidity: Double
    var pressure: Measurement<UnitPressure>
    var id: String { code }
    
}

extension CurrentWeatherInfo {
    init(_ forecast: CurrentWeather) {
        date = forecast.date
//        condition = forecast.condition.description
        symbolName = forecast.symbolName
        temperature = forecast.temperature
        windSpeed = forecast.wind.speed
        uvIndex = forecast.uvIndex.value
        humidity = forecast.humidity
        pressure = forecast.pressure.converted(to: .inchesOfMercury)
        code = forecast.metadata.location.description
    }
}
