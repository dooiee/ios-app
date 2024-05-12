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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var sensorDataManager: SensorDataManager
    
    @State private var selected: String = "1D"
    @State private var showSettingsPage: Bool = false
    @State private var offset = CGSize.zero

    var title: String
    var legendUnits: String
    var accentColor: Color

    let plotIntervals: [String] = ["LIVE", "1D", "1W", "1M", "3M", "1Y", "ALL"]
    let timestampIntervals: [Int] = [1_000*60*60, 1_000*60*60*23, 1_000*60*60*24*7, 1_000*60*60*24*30, 1_000*60*60*24*90, 1_000*60*60*24*365, Int(Date().timeIntervalSinceReferenceDate*1_000)]

    var body: some View {
        VStack {
            parameterPlotSection
            plotViewsForTimeIntervalSection
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
                Text("Select an interval to fetch data.")
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

            // Overlay for the fetching data text
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    .scaleEffect(1.5) // Make the progress view larger if needed
                Text("Fetching Data...")
                    .font(.subheadline)
                    .foregroundColor(accentColor)
                    .padding(.top, 8) // Adjust spacing to match your design needs
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
                    .padding()
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
        HStack {
            ForEach(plotIntervals, id: \.self) { interval in
                Button(action: {
                    withAnimation {
                        selected = interval
                    }
                }) {
                    Text(interval)
                        .padding()
                        .background(selected == interval ? accentColor : Color.clear)
                        .foregroundColor(selected == interval ? .white : accentColor)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func fetchData() {
        if let index = plotIntervals.firstIndex(of: selected) {
            let interval = timestampIntervals[index]
            sensorDataManager.fetchSensorData(parameter: title, interval: TimeInterval(interval))
        }
    }
}

#Preview {
    ParameterDetailView(title: "Temperature", legendUnits: " F", accentColor: Color.theme.accent)
        .environmentObject(UserSettings())
        .environmentObject(SensorDataManager())
}
