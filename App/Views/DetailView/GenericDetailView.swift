//
//  GenericDetailView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 5/18/22.
//

import SwiftUI
import SwiftUICharts
import CoreMedia
import OrderedCollections
import WeatherKit
import CoreLocation

struct GenericDetailView: View {
    
    @Environment(\.currentTab) var tab
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @Namespace private var namespace
    @EnvironmentObject private var vm: FirebaseDataService
    @StateObject private var fvm = FirebaseDataService()
    @StateObject private var fdr = FirebaseDataRetreivalForInterval()
    @State var selected: String = "1D"
    let weatherService = WeatherService.shared
    @State private var weather: CurrentWeather?
    @State var showSettingsPage: Bool = false
    @State private var offset = CGSize.zero
    
    var title: String
    var legendUnits: String
    var accentColor: Color
    
    let plotIntervals: [String] = ["LIVE", "1D", "1W", "1M", "3M", "1Y", "ALL"]
    let timestampIntervals: [Int] = [1_000*60*60, 1_000*60*60*23, 1_000*60*60*24*7, 1_000*60*60*24*30, 1_000*60*60*24*90, 1_000*60*60*24*365, Int(Date().timeIntervalSinceReferenceDate*1_000)] // changed the 1D time from 24 hours to 23 to stop values from 24 hours ago affecting average value of the current hour which yielded incorrect plot value.
    let pondLocation: CLLocation = CLLocation(latitude: 30.26426, longitude: -97.74750) // coordinates have been changed to keep pond location undisclosed
    
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
                        Image(systemName: "gearshape.fill").foregroundColor(Color.primary).scaleEffect(1.3)
                    }
                }.padding(.horizontal)
//                    .fullScreenCover(isPresented: $showSettingsPage) {
//                        GenericViewSettings()
//                    }
                ZStack {
                    colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
                    ScrollView {
                        parameterPlotSection
                        plotViewsForTimeIntervalSection
                        lazyVColumnSection
                        lazyVGridSection
                    } // ScrollView
                } // ZStack
            } // VStack
            if showSettingsPage {
                GenericViewSettings(showSettingsPage: $showSettingsPage).offset(x: offset.width).opacity(2 - Double(abs(offset.width / 150)))
//                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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
//                                presentationMode.wrappedValue.dismiss()
                            } else {
                                offset = .zero
                            }
                        }
                    )
            }                
        } // ZStack
    } // View
} // struct

extension GenericDetailView {
    private var parameterPlotSection: some View {
        //TODO: Make generic hold data for each interval, maybe created within the generic struct, then just reference each orderedDict by array index so the generic forEach can be kept.
        VStack (alignment: .center) {
            ForEach(plotIntervals, id: \.self) { interval in
                if selected == interval {
                    if (fdr.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval?.values.elements != nil) {
                        plotWithFetchedData(orderedDictForInterval: fdr.returnedParameterValuesForTimeInterval.returnedParameterValuesForInterval!)
                    }
                    else {
                        if fdr.returnedParameterValuesForTimeInterval.returnedErrorValuesForInterval == true {
                            placeholderPlotErrorFetchingData
                        }
                        else {
                            placeholderPlotWhileFetchingData
                        }
                    }
                }
            }
        }
        .onAppear {
            selected = GenericViewSettings(showSettingsPage: $showSettingsPage).defaultPlotInterval
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                fdr.fetchFirebaseDataForInterval(parameter: title, for: timestampIntervals[plotIntervals.firstIndex(of: selected)!])
            }
        }
        .onDisappear {
            fdr.clearFetchedFirebaseDataForIntervals()
        }
    }
    private var placeholderPlotWhileFetchingData: some View {
        ZStack {
            let chartStyle = ChartStyle(backgroundColor: Color("LightDarkModeChartBackground"), accentColor: accentColor.opacity(0.8), secondGradientColor: accentColor.opacity(0.8), textColor: Color.primary, legendTextColor: Color.primary, dropShadowColor: Color.primary)
            VStack {
                LineView(data: [0.0], legend: String(" ") + "XXXX", style: chartStyle, dataKeys: [""]).padding(.horizontal, 5.0).redacted(reason: .placeholder)
            }
            .frame(height: 315) // changed from 350
            VStack {
                ProgressView().padding(.all).progressViewStyle(CircularProgressViewStyle(tint: accentColor)).padding(.bottom, -10.0)
                Text("Fetching Data...").font(.subheadline).foregroundColor(Color.secondary)
            }
        }
    }
    private var placeholderPlotErrorFetchingData: some View {
        ZStack {
            let chartStyle = ChartStyle(backgroundColor: Color("LightDarkModeChartBackground"), accentColor: accentColor.opacity(0.8), secondGradientColor: accentColor.opacity(0.8), textColor: Color.primary, legendTextColor: Color.primary, dropShadowColor: Color.primary)
            VStack {
                LineView(data: [0.0], legend: String(" ") + "XXXX", style: chartStyle, dataKeys: [""]).padding(.horizontal, 5.0).redacted(reason: .placeholder)
            }
            .frame(height: 315) // changed from 350
            VStack {
                Image(systemName: "exclamationmark.triangle").foregroundColor(accentColor).padding(.all).padding(.bottom, -5.0)
                Text("Error Fetching Data...").font(.subheadline).foregroundColor(Color.secondary)
            }
        }
    }
    @ViewBuilder private func plotWithFetchedData(orderedDictForInterval: OrderedDictionary<String, Double>) -> some View {
        let chartStyle = ChartStyle(backgroundColor: Color("LightDarkModeChartBackground"), accentColor: accentColor.opacity(0.8), secondGradientColor: accentColor.opacity(0.8), textColor: Color.primary, legendTextColor: Color.primary, dropShadowColor: Color.primary)
        LineView(data: orderedDictForInterval.values.elements, legend: legendUnits, style: chartStyle, dataKeys: orderedDictForInterval.keys.elements) // removed title
            .padding(.horizontal, 5.0)
//            .offset(y: -20)
            .frame(height: 315) // changed to 300
    }
    private var plotViewsForTimeIntervalSection: some View {
        VStack {
            HStack {
                ForEach(plotIntervals, id: \.self) { interval in
                    Spacer()
                        ZStack {
                            if selected == interval {
                                RoundedRectangle(cornerRadius: 8).foregroundColor(accentColor).matchedGeometryEffect(id: "rectangle", in: namespace).frame(width: 35, height: 25)
                            }
                            Text(interval).font(.caption).foregroundColor(selected == interval ? Color.black : accentColor).fontWeight(.bold).frame(width: 35, height: 25)
                        }
                        .onTapGesture {
                            withAnimation(.linear) {
                                selected = interval
                            }
                            if selected == interval {
                                fdr.returnedParameterValuesForTimeInterval.returnedErrorValuesForInterval = false
                                let plotInterval = timestampIntervals[plotIntervals.firstIndex(of: interval)!]
                                fdr.fetchFirebaseDataForInterval(parameter: title, for: plotInterval)
                            }
                        }
                    Spacer()
                }
            }.padding(.horizontal)
        }//.padding(.top, 10.0) // commented out
    }
    private var lazyVColumnSection: some View {
        LazyVGrid(columns: column, alignment: .center) {
            ForEach(0..<2) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
//                        .opacity(0.3)
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
        }
        .padding([.top, .leading, .trailing])
        
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
//                            CurrentWeatherView()
                            if let weather {
                                Text("\(weather.uvIndex.value)").font(.system(size: 35, weight: .semibold))
                                Text("\(weather.uvIndex.category.description)")
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
                            Spacer()
                        }.padding()
                    }
                }
            }
            .task {
                do {
                    let pondLocation: CLLocation = CLLocation(latitude: 30.26426, longitude: -97.74750) // coordinates have been changed to keep pond location undisclosed
                    self.weather = try await weatherService.weather(for: pondLocation, including: .current)
//                    print(weather as Any)
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

struct GenericDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GenericDetailView(title: "Parameter Title", legendUnits: "Parameter Units", accentColor: Color.theme.accent)
    }
}
