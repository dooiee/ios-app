//
//  GenericViewSettings.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 8/19/22.
//

import SwiftUI

struct GenericViewSettings: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL
    let urlFirebaseConsole = "https://console.firebase.google.com" // url has been changed to generic firebase url
    @State var defaultPlotInterval: String = "1D"
    let plotIntervals: [String] = ["LIVE", "1D", "1W", "1M", "3M", "1Y", "ALL"]
    @Binding var showSettingsPage: Bool
    
    var body: some View {
        ZStack {
            colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
            VStack {
                headerSection
                List {
                    firebaseLinkSection
                    plotSection
                }
                Spacer()
            }
            .background(colorScheme == .light ? Color(red: 0.949, green: 0.949, blue: 0.97) : Color.black)
//            .gesture(
//                    DragGesture().onEnded { value in
//                        if value.location.x - value.startLocation.x > 150 {
//                            /// Use  for iOS 14 and below
//                            withAnimation(.spring()) { showSettingsPage.toggle() }
//                            presentationMode.wrappedValue.dismiss()
//                        }
//                    }
//                )
        }
    }
}
extension GenericViewSettings {
    private var headerSection: some View {
        HStack {
            Button {
                //presentationMode.wrappedValue.dismiss()
                withAnimation(.spring()) { showSettingsPage = false }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(colorScheme == .light ? Color.black : Color.secondary)
                    .font(.title)
                    .padding()
            }
            Spacer()
            Text("Settings").font(.title2).bold()
            Spacer()
            Button {
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.clear)
                    .font(.title)
                    .padding()
            }
        }
    }
    private var firebaseLinkSection: some View {
        Section(header: Text("Links")) {
            HStack {
                Image("firebase.logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.trailing, 2.0)
                    .frame(width: 22, height: 22)
                Button {
                    openURL(URL(string: urlFirebaseConsole)!)
                } label: {
                    HStack {
                        Text("Go To Firebase Console").foregroundColor(Color.blue)
                        Image(systemName: "link").foregroundColor(Color.blue)
                    }
                }
            }
        } // Section
    }
    private var plotSection: some View {
        Section(header: Text("Plot Settings")) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill").symbolRenderingMode(.palette).foregroundStyle(Color.white, Color.cyan)
                    .imageScale(.large).padding(.trailing, 2.0).offset(x: -1)
//                Text("Default Plot Interval: \(defaultPlotInterval)")
                Spacer()
                Picker(selection: $defaultPlotInterval) {
                    ForEach(plotIntervals, id: \.self) { interval in
                        Text("\(interval)").tag("\(interval)")
                    }
                } label: {
                    Text("Default Plot Interval")
                }.pickerStyle(MenuPickerStyle())
            }
        } // Section
    }
}

struct GenericViewSettings_Previews: PreviewProvider {
    static var previews: some View {
        GenericViewSettings(showSettingsPage: .constant(true))
    }
}
