//
//  ParameterDetailView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 5/11/24.
//

import SwiftUI
import SwiftUICharts
import CoreMedia
import OrderedCollections
import WeatherKit
import CoreLocation


struct ParameterDetailView: View {
    @Environment(\.currentTab) var tab
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @Namespace private var namespace
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var sensorDataManager: SensorDataManager
    
    let weatherService = WeatherService.shared
    @State private var weather: CurrentWeather?
    @State private var selected: String = "1D"
    @State private var showSettingsPage: Bool = false
    @State private var offset = CGSize.zero

    var title: String
    var legendUnits: String
    var accentColor: Color

    let plotIntervals: [String] = ["LIVE", "1D", "1W", "1M", "3M", "1Y", "ALL"]
    let timestampIntervals: [Int] = [1_000*60*60, 1_000*60*60*23, 1_000*60*60*24*7, 1_000*60*60*24*30, 1_000*60*60*24*90, 1_000*60*60*24*365, Int(Date().timeIntervalSinceReferenceDate*1_000)]
    
    let column: [GridItem] = [
        GridItem(.flexible(), spacing: nil, alignment: nil)]
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: nil, alignment: nil),
        GridItem(.flexible(), spacing: nil, alignment: nil)]

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: { tab.wrappedValue = .home }) {
                        Image(systemName: "chevron.left").fontWeight(.medium).foregroundColor(colorScheme == .light ? Color.black : Color.secondary).scaleEffect(1.3)
                    }
                    Spacer()
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: { withAnimation(.spring()) { showSettingsPage.toggle() } }) {
                        Image(systemName: "gearshape.fill").foregroundColor(colorScheme == .light ? Color.black : Color.secondary).scaleEffect(1.3)
                    }
                }.padding(.horizontal)
                ZStack {
                    colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
                    ScrollView {
                        parameterPlotSection
                        plotViewsForTimeIntervalSection
                        lazyVColumnSection
                        lazyVGridSection
                    }
                    .onAppear {
                        selected = userSettings.defaultPlotInterval
                        fetchData()
                    }
                    .onChange(of: selected) { _ in
                        fetchData()
                    }
                    .onDisappear {
                        sensorDataManager.clearFetchedData()
                    }
                }
            }
            if showSettingsPage {
                GenericViewSettings(showSettingsPage: $showSettingsPage)
                    .offset(x: offset.width)
                    .opacity(2 - Double(abs(offset.width / 150)))
                    .transition(showSettingsPage ? .move(edge: .bottom) : .move(edge: .trailing))
                .gesture(
                    DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { value in
                        if value.location.x - value.startLocation.x > 150 {
                            withAnimation(.spring()) { showSettingsPage.toggle() }
                            offset = .zero
//                                  presentationMode.wrappedValue.dismiss()
                        } else {
                            offset = .zero
                        }
                    }
                )
            }
        } // ZStack
//        VStack {
//            parameterPlotSection
//            plotViewsForTimeIntervalSection
//        }
//        .onAppear {
//            selected = userSettings.defaultPlotInterval
//            fetchData()
//        }
//        .onChange(of: selected) { _ in
//            fetchData()
//        }
//        .onDisappear {
//            sensorDataManager.clearFetchedData()
//        }
    }
    
    private var parameterPlotSection: some View {
        VStack {
            switch sensorDataManager.state {
            case .loading:
                placeholderPlotWhileFetchingData
            case .loaded:
                if let data = sensorDataManager.sensorData[selected], !data.isEmpty {
                    plotWithFetchedData(orderedDictForInterval: data)
                } else {
                    placeholderPlotErrorFetchingData(errorMessage: "No data available")
                }
            case .error(let errorMessage):
                placeholderPlotErrorFetchingData(errorMessage: errorMessage)
            default:
                placeholderPlotWhileFetchingData
            }
        }
    }
    
    private var placeholderPlotWhileFetchingData: some View {
        ZStack {
            let chartStyle = ChartStyle(
                backgroundColor: Color("LightDarkModeChartBackground"),
                accentColor: accentColor.opacity(0.8),
                secondGradientColor: accentColor.opacity(0.8),
                textColor: Color.primary,
                legendTextColor: Color.primary,
                dropShadowColor: Color.primary
            )
            // Display a LineView with placeholder data
            LineView(data: [0.0], legend: String(" ") + "XXXX", style: chartStyle, dataKeys: [""])
                .frame(height: 315)
                .padding(.horizontal)
                .redacted(reason: .placeholder)

            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    .padding(.all)
                    .padding(.bottom, -10.0)
                Text("Fetching Data...")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
                Spacer()
            }
        }
    }
    
    private func placeholderPlotErrorFetchingData(errorMessage: String) -> some View {
        ZStack {
            let chartStyle = ChartStyle(
                backgroundColor: Color("LightDarkModeChartBackground"),
                accentColor: accentColor.opacity(0.8),
                secondGradientColor: accentColor.opacity(0.8),
                textColor: Color.primary,
                legendTextColor: Color.primary,
                dropShadowColor: Color.primary
            )
            LineView(data: [0.0], legend: "Error", style: chartStyle, dataKeys: [""])
                .redacted(reason: .placeholder)
                .frame(height: 315)
                .padding(.horizontal)

            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(accentColor)
                    .padding(.all)
                    .padding(.bottom, -5.0)
                Text(errorMessage) // Using the passed error message
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func plotWithFetchedData(orderedDictForInterval: OrderedDictionary<String, Double>) -> some View {
        let chartStyle = ChartStyle(
            backgroundColor: Color("LightDarkModeChartBackground"),
            accentColor: accentColor.opacity(0.8),
            secondGradientColor: accentColor.opacity(0.8),
            textColor: Color.primary,
            legendTextColor: Color.primary,
            dropShadowColor: Color.primary
        )

        LineView(
            data: orderedDictForInterval.values.elements, // Array of Double, representing the data points
            legend: legendUnits, // String, representing the units or description for the legend
            style: chartStyle, // ChartStyle, representing the styling for the line chart
            dataKeys: orderedDictForInterval.keys.elements // Array of String, representing the keys corresponding to data points
        )
        .padding(.horizontal, 5.0)
        .frame(height: 315) // Adjust the height as needed
    }

    private var plotViewsForTimeIntervalSection: some View {
        VStack {
            HStack {
                ForEach(plotIntervals, id: \.self) { interval in
                    Spacer()
                        ZStack {
                            if selected == interval {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(accentColor)
                                    .matchedGeometryEffect(id: "rectangle", in: namespace)
                                    .frame(width: 35, height: 25)
                            }
                            Text(interval)
                                .font(.caption)
                                .foregroundColor(selected == interval ? Color.black : accentColor)
                                .fontWeight(.bold)
                                .frame(width: 35, height: 25)
                        }
                        .onTapGesture {
                            withAnimation(.linear) {
                                selected = interval
                            }
                        }
                    Spacer()
                }
            }.padding(.horizontal)
        }
    }
    
    private func fetchData() {
        if let index = plotIntervals.firstIndex(of: selected) {
            let interval = timestampIntervals[index]
            sensorDataManager.fetchSensorData(parameter: title, interval: TimeInterval(interval))
        }
    }
    
    private var lazyVColumnSection: some View {
        LazyVGrid(columns: column, alignment: .center) {
            ForEach(0..<2) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(colorScheme == .light ? Color.gray.opacity(0.3) : Color.theme.accentNightModeGray)
                    if index == 1 {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("10-DAY FORECAST", systemImage: "calendar.badge.clock")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Divider().background(Color.primary)
                            Spacer()
                            DailyWeatherView()
                        }.padding()
                    }
                    if index == 0 {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("HOURLY FORECAST", systemImage: "clock")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Divider().background(Color.primary)
                            HourlyForecastView()
                        }
                        .padding([.top, .leading, .trailing])
                        .padding(.bottom, 5.0)
                    }
                }.frame(height: index == 0 ? 150: 300)
            }
        }.padding([.top, .leading, .trailing])
    }
    
    private var lazyVGridSection: some View {
        LazyVGrid(columns: columns, alignment: .center) {
            ForEach(0..<6) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .frame(height: 150)
                        .foregroundColor(colorScheme == .light ? Color.gray.opacity(0.3) : Color.theme.accentNightModeGray)
                    if index == 0 {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("AIR TEMPERATURE", systemImage: "thermometer")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Divider().background(Color.primary)
                            if let weather {
                                Text("\(weather.apparentTemperature.converted(to: .fahrenheit).value, specifier: "%.1f")\u{00B0}").font(.system(size: 29, weight: .semibold)).padding()
                            } else {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                            Spacer()
                        }.padding()
                    }
                    if index == 1 {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("UV INDEX", systemImage: "sun.max.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Divider().background(Color.primary)
                            if let weather {
                                Text("\(weather.uvIndex.value)").font(.system(size: 35, weight: .semibold))
                                Text("\(weather.uvIndex.category.description)")
                            } else {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                            Spacer()
                        }.padding()
                    }
                    if index == 2 {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("RAINFALL", systemImage: "drop.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Divider().background(Color.primary)
                            DailyWeatherView2()
                            Spacer()
                        }.padding()
                    }
                    if index == 3 {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("WIND", systemImage: "wind")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Divider().background(Color.primary)
                            if let weather {
                                Text("\(weather.wind.speed.converted(to: .milesPerHour).value, specifier: "%.0f") mph \(weather.wind.compassDirection.abbreviation)").font(.system(size: 29, weight: .semibold)).padding(.horizontal)
                            } else {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                            Spacer()
                        }.padding()
                    }
                    if index == 4 {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("HUMIDITY", systemImage: "humidity")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Divider().background(Color.primary)
                            if let weather {
                                Text("\(weather.humidity*100, specifier: "%.0f")%").font(.system(size: 30, weight: .semibold)).padding()
                            } else {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                            Spacer()
                        }.padding()
                    }
                    if index == 5 {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("AIR QUALITY", systemImage: "aqi.medium")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Divider().background(Color.primary)
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                Spacer()
                            }
                            Spacer()
                        }.padding()
                    }
                }
            }
            .task {
                do {
                    self.weather = try await weatherService.weather(for: Secrets.POND_COORDINATES, including: .current)
                    print("Returned Current Weather Data.")
                } catch {
                    print(error)
                }
            }
        }
        .padding([.leading, .bottom, .trailing])
        .foregroundColor(Color.secondary)
    }
}

#Preview {
    ParameterDetailView(title: "Temperature", legendUnits: " F", accentColor: Color.theme.accent)
        .environmentObject(UserSettings())
        .environmentObject(SensorDataManager())
}
