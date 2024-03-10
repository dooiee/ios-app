//
//  ArduinoStatisticsView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 8/29/22.
//

import SwiftUI

struct ArduinoStatisticsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @Binding var showArduinoStatisticsView: Bool
    @StateObject private var firebaseArduinoStatistics = FirebaseArduinoStatistics()
    
    var body: some View {
        ZStack {
            colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
            VStack {
                headerSection
                List {
                    mkrStatistics
                    espStatistics
                }
            }.onAppear {
                firebaseArduinoStatistics.getStatistics()
            }
            .background(colorScheme == .light ? Color(red: 0.949, green: 0.949, blue: 0.97) : Color.black)
        }
    }
}

extension ArduinoStatisticsView {
    private var headerSection: some View {
        HStack {
            Button {
                showArduinoStatisticsView = false
            } label: {
                Image(systemName: "chevron.left")
                Text("Back")
            }.foregroundColor(Color.blue)
                .font(.headline).padding()
            Spacer()
            Text("Lifetime Statistics").font(.headline)
            Spacer()
            Button {
            } label: {
                Image(systemName: "chevron.left")
                Text("Back")
            }.foregroundColor(Color.clear)
                .font(.headline).padding()
        }
    }
    private var mkrStatistics: some View {
        Section(header: Text("MKR 1010")) {
            HStack {
                Text("Total Resets:").font(.callout)
                Spacer()
                if firebaseArduinoStatistics.mkrStatistics.isEmpty {
                    ProgressView()
                } else {
                    ForEach (firebaseArduinoStatistics.mkrStatistics, id: \.self) { entries in
                        Text("\(entries.resetCount)").font(.callout)
                    }
                }
            }
            HStack {
                Text("Wi-Fi Disconnects:").font(.callout)
                Spacer()
                ProgressView()
                //TODO: Add Wi-Fi disconnects counter
//                Text("3").font(.callout)
            }
            HStack {
                Text("Reliability:").font(.callout)
                Spacer()
                Text("82%").font(.callout)
            }
        }
    }
    private var espStatistics: some View {
        Section(header: Text("ESP32"), footer: Text("Reliability is a measure of the percentage of time spent online")) {
            HStack {
                Text("Total Resets:").font(.callout)
                Spacer()
                if firebaseArduinoStatistics.espStatistics.isEmpty {
                    ProgressView()
                } else {
                    ForEach (firebaseArduinoStatistics.espStatistics, id: \.self) { entries in
                        Text("\(entries.resetCount)").font(.callout)
                    }
                }
            }
            HStack {
                Text("Wi-Fi Disconnects:").font(.callout)
                Spacer()
                //TODO: Add Wi-Fi disconnects counter
                ProgressView()
//                Text("2").font(.callout)
            }
            HStack {
                Text("Reliability:").font(.callout)
                Spacer()
                Text("78%").font(.callout)
            }
        }
    }
}

struct ArduinoStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        ArduinoStatisticsView(showArduinoStatisticsView: .constant(true))
    }
}
