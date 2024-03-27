//
//  SystemStatusView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 5/11/23.
//

import SwiftUI

struct SystemStatusView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL
    
    @StateObject private var arduinoVM = ArduinoViewModel()

    let urlFirebaseConsole = Constants.FirebaseDb.Credentials.FIREBASE_CONSOLE_URL
    
    @State var showArduinoControl = false
    @State var arduinoReset = false
    @State var confirmArduinoReset = false
    @State var arduinoCurrentlyResetting = false
    @State var esp32Reset = false
    @State var confirmESP32Reset = false
    @State var esp32CurrentlyResetting = false
    @StateObject private var firebaseArduinoControl = FirebaseArduinoControl()
    
    @State var oldLastUpdateValue: Int? = nil
    @State var lastUpdateValueChanged: Bool = false
    @State var wifiRssiChanged: Bool = false
    @State var oldWifiRssiValue: Int? = nil
    @State var animateValueChange: Bool = false
    
    @State var showArduinoStatisticsView: Bool = false
    
    @State private var showingErrorAlert = false
    
    var body: some View {
        ZStack {
            colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
            VStack {
                headerSection
                List {
                    statusSection
                    centralHubStatusSection
                    peripheralStatusSection
                    rfTransmitterStatusSection
                    wifiStatusSection
                    onlineSinceSection
                    resetStatusSection
                    firebaseLinkSection
                    statisticsSection
                }
            }.onAppear {
                firebaseArduinoControl.getArduinoStatus()
                showArduinoControl = firebaseArduinoControl.getArduinoResetStateBool()
            }
            .onChange(of: firebaseArduinoControl.arduinoStatus) { newValue in
                                if oldWifiRssiValue == nil {
                                    oldWifiRssiValue = newValue[0].wifiRssi
                                }
                                if oldWifiRssiValue != newValue[0].wifiRssi {
                                    oldWifiRssiValue = newValue[0].wifiRssi
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        wifiRssiChanged.toggle()
                                        //oldWifiRssiValue = newValue[0].wifiRssi
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        wifiRssiChanged.toggle()
                                    }
                                }
                                if oldLastUpdateValue == nil {
                                    oldLastUpdateValue = newValue[0].lastUpload
                                }
                                if oldLastUpdateValue != newValue[0].lastUpload {
                                    oldLastUpdateValue = newValue[0].lastUpload
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        lastUpdateValueChanged.toggle()
                                        //oldWifiRssiValue = newValue[0].wifiRssi
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        lastUpdateValueChanged.toggle()
                                    }
                                }
                            }
            .background(colorScheme == .light ? Color(red: 0.949, green: 0.949, blue: 0.97) : Color.black)
            if showArduinoStatisticsView {
                ArduinoStatisticsView(showArduinoStatisticsView: $showArduinoStatisticsView)
            }
        }
    }
}

extension SystemStatusView {
    private var headerSection: some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(colorScheme == .light ? Color.black : Color.secondary)
                    .font(.title)
                    .padding()
            }
            Spacer()
            Text("System Status").font(.title2).bold()
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
    
    
    private var statusSection: some View {
        Section(header: Text("Status")) {
            HStack {
                Image(systemName: "cable.connector.horizontal").symbolRenderingMode(.hierarchical)
                    .imageScale(.large).offset(x: -1)
                Text("Central Hub")
                Spacer()
                if let ledStatus = arduinoVM.ledStatus {
                    Text("Online")
                        .foregroundColor(.secondary)
                        .font(.subheadline).bold()
                    Circle()
                        .foregroundColor(Color(red: Double(ledStatus.red)/255, green: Double(ledStatus.green)/255, blue: Double(ledStatus.blue)/255, opacity: Double(ledStatus.intensity)/100))
                        .frame(width: 12.0, height: 12.0)
                        .padding(.horizontal, 2)
                } else if arduinoVM.errorMessage != nil {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            showingErrorAlert = true
                        }
                    .alert(isPresented: $showingErrorAlert) {
                        Alert(title: Text("Error"), message: Text(arduinoVM.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
                    }
                } else {
                    Text("Fetching...")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
        }
        .onAppear {
            arduinoVM.fetchLEDStatus()
        }
    }

    private var centralHubStatusSection: some View {
        ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
            Section(header: Text("Central Hub")) {
                HStack {
                    Image(systemName: "wifi.square.fill").symbolRenderingMode(.multicolor)
                        .imageScale(.large).padding(.trailing, 2.0).offset(x: -1)
                    Text("MKR 1010")
                    Spacer()
                    if parameter.wifiStatus == 3 {
                        Text("Connected")
                    }
                    else if parameter.wifiStatus == 6 {
                        Text("Disconnected")
                    }
                    else {
                        Text("Not Connected")
                    }
                    Text("(\(parameter.wifiStatus))")
                }
                HStack {
                    Image(systemName: "wifi.square.fill").symbolRenderingMode(.multicolor)
                        .imageScale(.large).padding(.trailing, 2.0).offset(x: -1)
                    Text("Nano 33 IoT")
                    Spacer()
                    if parameter.wifiStatus == 3 {
                        Text("Connected")
                    }
                    else if parameter.wifiStatus == 6 {
                        Text("Disconnected")
                    }
                    else {
                        Text("Not Connected")
                    }
                    Text("(\(parameter.wifiStatus))")
                }
                HStack {
                    Image(systemName: "clock.badge.checkmark.fill").symbolRenderingMode(.palette).foregroundStyle(Color.green, Color.cyan)
                        .imageScale(.large).padding(.trailing, 5.0)
                    Text("Online Since:").font(.callout)
                    Spacer()
                    Text("\(parameter.onlineSince.latest.convertStringToTimestamp(dateformat: "EEE MM/dd @ h:mm a"))").font(.callout)
                }
                HStack {
                    Image(systemName: "wifi.square.fill").symbolRenderingMode(.multicolor)
                        .imageScale(.large).padding(.trailing, 2.0).offset(x: -1)
                    Text("Peripheral BLE")
                    Spacer()
                    if parameter.wifiStatus == 3 {
                        Text("Connected")
                            .foregroundColor(.secondary)
                            .font(.subheadline).bold()
                        Circle()
                            .foregroundColor(Color.theme.batteryGreen)
                            .frame(width: 12.0, height: 12.0)
                            .padding(.horizontal, 2)
                    }
                    else if parameter.wifiStatus == 6 {
                        Text("Disconnected")
                        Circle()
                            .foregroundColor(Color.theme.batteryRed)
                            .frame(width: 12.0, height: 12.0)
                            .padding(.horizontal, 2)
                    }
                    else {
                        Text("Not Connected")
                    }
                }
            } // Section
        } // ForEach
    }
    private var peripheralStatusSection: some View {
        ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
            Section(header: Text("Pond Sensor Controller")) {
                HStack {
                    Image(systemName: "wifi.square.fill").symbolRenderingMode(.multicolor)
                        .imageScale(.large).padding(.trailing, 2.0).offset(x: -1)
                    Text("Peripheral BLE")
                    Spacer()
                    if parameter.wifiStatus == 3 {
                        Text("Connected")
                        Circle()
                            .foregroundColor(Color.theme.batteryGreen)
                            .frame(width: 12.0, height: 12.0)
                            .padding(.horizontal, 2)
                    }
                    else if parameter.wifiStatus == 6 {
                        Text("Disconnected")
                    }
                    else {
                        Text("Not Connected")
                    }
                }
                HStack {
                    Image(systemName: "clock.badge.checkmark.fill").symbolRenderingMode(.palette).foregroundStyle(Color.green, Color.cyan)
                        .imageScale(.large).padding(.trailing, 5.0)
                    Text("Online Since:").font(.callout)
                    Spacer()
                    Text("\(parameter.onlineSince.latest.convertStringToTimestamp(dateformat: "EEE MM/dd @ h:mm a"))").font(.callout)
                }
            } // Section
        } // ForEach
    }
    private var rfTransmitterStatusSection: some View {
        ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
            Section(header: Text("Underwater LED Controller")) {
                HStack {
                    Image(systemName: "wifi.square.fill").symbolRenderingMode(.multicolor)
                        .imageScale(.large).padding(.trailing, 2.0).offset(x: -1)
                    Text("ESP32")
                    Spacer()
                    if parameter.wifiStatus == 3 {
                        Text("Connected")
                    }
                    else if parameter.wifiStatus == 6 {
                        Text("Disconnected")
                    }
                    else {
                        Text("Not Connected")
                    }
                    Text("(\(parameter.wifiStatus))")
                }
                HStack {
                    Image(systemName: "wifi.square.fill").symbolRenderingMode(.multicolor)
                        .imageScale(.large).padding(.trailing, 2.0).offset(x: -1)
                    Text("Nano 33 IoT")
                    Spacer()
                    if parameter.wifiStatus == 3 {
                        Text("Connected")
                    }
                    else if parameter.wifiStatus == 6 {
                        Text("Disconnected")
                    }
                    else {
                        Text("Not Connected")
                    }
                    Text("(\(parameter.wifiStatus))")
                }
            } // Section
        } // ForEach
    }
    private var wifiStatusSection: some View {
        ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
            Section(header: Text("Wi-Fi Status")) {
                HStack {
                    Image(systemName: "wifi.square.fill").symbolRenderingMode(.multicolor)
                        .imageScale(.large).padding(.trailing, 2.0).offset(x: -1)
                    Text("Wi-Fi:")
                    Spacer()
                    if parameter.wifiStatus == 3 {
                        Text("Connected")
                    }
                    else if parameter.wifiStatus == 6 {
                        Text("Disconnected")
                    }
                    else {
                        Text("Not Connected")
                    }
                    Text("(\(parameter.wifiStatus))")
                }
                wifiRSSISectionWithAnimation
            } // Section
        } // ForEach
    }
    private var wifiRSSISectionWithAnimation: some View {
        ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
            HStack {
                if parameter.wifiRssi >= -60 {
                    if parameter.wifiRssi == -1 {
                        Image(systemName: "wifi.slash").padding(.trailing, 6.0).symbolRenderingMode(.multicolor)
                    } else {
                        Image(systemName: "wifi", variableValue: 1.0).padding(.trailing, 6.0).symbolRenderingMode(.multicolor)
                    }
                } else if parameter.wifiRssi < -60 && parameter.wifiRssi >= -70  {
                    Image(systemName: "wifi", variableValue: 0.5).padding(.trailing, 6.0)
                } else if parameter.wifiRssi < -70 {
                    Image(systemName: "wifi", variableValue: 0.2).padding(.trailing, 6.0)
                }
                Text("RSSI:")
                Spacer()
                ZStack {
                    ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
                        Text("\(parameter.wifiRssi)")
                        RoundedRectangle(cornerRadius: 3)
                            .foregroundColor(wifiRssiChanged ? Color.secondary.opacity(0.3) : Color.clear)
                            .frame(width: 30, height: 18)
                    } // ForEach
                } // ZStack
            } // HStack
        } // ForEach
    }
    private var onlineSinceSection: some View {
        ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
            Section(header: Text("Online Since")) {
                HStack {
                    Image(systemName: "clock.badge.checkmark.fill").symbolRenderingMode(.palette).foregroundStyle(Color.green, Color.blue)
                        .imageScale(.large).padding(.trailing, 5.0)
                    Text("Latest:").font(.callout)
                    Spacer()
                    Text("\(parameter.onlineSince.latest.convertStringToTimestamp(dateformat: "EEE MM/dd @ h:mm a"))").font(.callout)
                }
                HStack {
                    Image(systemName: "clock.arrow.2.circlepath").symbolRenderingMode(.palette).foregroundStyle(Color.black, Color.blue)
                        .imageScale(.large).padding(.trailing, 0.0).offset(x: -1)
                    Text("Time Before:")
                        .font(.callout)
                    Spacer()
                    Text("\(parameter.onlineSince.timeBeforeThat.convertStringToTimestamp(dateformat: "EEE MM/dd @ h:mm a"))").font(.callout)
                }
                HStack {
                    Image(systemName: "timer").symbolRenderingMode(.multicolor)
                        .imageScale(.large).padding(.trailing, 4.0)
                    Text("Last Power Cycle Runtime:")
                        .font(.callout)
                    Spacer()
                    if parameter.onlineSince.totalRuntimeOfLastPowerCycle >= 60 && parameter.onlineSince.totalRuntimeOfLastPowerCycle < 1440 {
                        let runtimeConversion = parameter.onlineSince.totalRuntimeOfLastPowerCycle/60
                        Text("\(runtimeConversion)").font(.callout)
                        Text("hrs").font(.callout)
                    } else if parameter.onlineSince.totalRuntimeOfLastPowerCycle >= 1440 {
                        let runtimeConversion = parameter.onlineSince.totalRuntimeOfLastPowerCycle/1440
                        Text("\(runtimeConversion)").font(.callout)
                        Text("days").font(.callout)
                    } else {
                        Text("\(parameter.onlineSince.totalRuntimeOfLastPowerCycle)").font(.callout)
                        Text("mins").font(.callout)
                    }
                }
            }
        }
    }
//    private func updateTimeSinceLastUpdate() -> some View {
//    }
    private var updateTimeSinceLastUpdate: some View {
        HStack {
            ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
                Text("Updated:")
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .foregroundColor(lastUpdateValueChanged ? Color.secondary.opacity(0.2) : Color.clear)
                        .frame(width: 65, height: 13)
                    let now = (Date().timeIntervalSince1970)
                    let lastUploadTime = Double(parameter.lastUpload/1_000)
                    let difference = lastUploadTime - now
                    let formatter = RelativeDateTimeFormatter()
                    if difference < 1 {
                        Text("less than a second ago")
                    } else {
                        Text("\(formatter.localizedString(fromTimeInterval: lastUploadTime - now))")
                    }
                }
                /*
                 //                        Text("Last Updated:\(parameter.lastUpload.convertIntLongToTimestamp(dateformat: "EEEE MM/dd @ h:mm a"))")
                 //                ZStack {
                 //                    RoundedRectangle(cornerRadius: 3)
                 //                        .foregroundColor(lastUpdateValueChanged ? Color.secondary.opacity(0.2) : Color.clear)
                 //                        .frame(width: 65, height: 13)
                 //                    let now = (Date().timeIntervalSince1970)
                 //                    let lastUploadTime = Double(parameter.lastUpload/1_000)
                 //                    let difference = lastUploadTime - now
                 //                    let formatter = RelativeDateTimeFormatter()
                 //                    Text("\(formatter.localizedString(fromTimeInterval: lastUploadTime - now))")
                                     
                 //                    Text("\(difference) = \(lastUploadTime) - \(now)")
                 //                    Text("\(parameter.lastUpload.convertIntLongToTimestamp(dateformat: "EEEE MM/dd @ h:mm a"))")
                                 //}
                 */
            }
        }
    }
    private var resetStatusSection: some View {
        ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
            Section(header: Text("Reset Status"), footer:
                        HStack {
                Text("Last Update:")
                Text("\(Date().addingTimeInterval(0), style: .relative) ago") // chose timer method beause screen only updates on changes of RSSI and last update time so it is accurate.
                // can do ternary operator so on appear we can get lastUploadTime - now and then once true just take the timer timer. Probably need to do a function to grab lastUpdate time and save that to variable.
            })
            {
                Toggle(isOn: $confirmArduinoReset) {
                    HStack {
                        Image(systemName: "bolt.slash.fill").symbolRenderingMode(.palette).foregroundStyle(Color.red, Color("AccentColorPeach"))
                            .imageScale(.large).padding(.trailing, 5.0)
                        Text("Reset:")
//                        let now: Int = Int(Date().timeIntervalSince1970)
//                        Text("\(now)")
                        Spacer()
                        if parameter.resetting == 1 {
                            Text("Arduino Reset In Progress...")
                                .foregroundColor(Color.secondary)
                                .font(.caption)
                                .padding(.top, 3.0)
                        }
                        Spacer()
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.theme.background))
                .alert(isPresented: $confirmArduinoReset, content: {
                    Alert(title: Text("Confirm Reset"), message: Text("Are you sure you would like to hard reset the Arduino MKR 1010?"), primaryButton: .default(Text("Yes"), action: {
                        firebaseArduinoControl.triggerArduinoReset()
                    }), secondaryButton: .destructive(Text("No"), action: {
                        confirmArduinoReset = false
                    }))
                })
                HStack {
                    Image(systemName: "bolt.badge.clock.fill").symbolRenderingMode(.palette).foregroundStyle(Color.blue, Color("AccentColorPeach")).padding(.trailing, 5.0).offset(x:-1).imageScale(.large)
                    Text("Last Reset:")
                    Spacer()
                    Text("\(parameter.lastExternalReset.convertIntLongToTimestamp(dateformat: "EEE MM/dd @ h:mm a"))")
                } // HStack
                Toggle(isOn: $confirmESP32Reset) {
                    HStack {
                        Image(systemName: "bolt.slash.fill").symbolRenderingMode(.palette).foregroundStyle(Color.red, Color("AccentColorPeach"))
                            .imageScale(.large).padding(.trailing, 5.0)
                        Text("ESP32 Reset:")
                        Spacer()
                        if parameter.esp32Resetting == 1 {
                            Text("ESP32 Reset In Progress...")
                                .foregroundColor(Color.secondary)
                                .font(.caption)
                                .padding(.top, 3.0)
                        }
                        Spacer()
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.theme.background))
                .alert(isPresented: $confirmESP32Reset, content: {
                    Alert(title: Text("Confirm Reset"), message: Text("Are you sure you would like to hard reset the ESP32?"), primaryButton: .default(Text("Yes"), action: {
                        firebaseArduinoControl.triggerESP32Reset()
                    }), secondaryButton: .destructive(Text("No"), action: {
                        confirmESP32Reset = false
                    }))
                })
            }
        }
    }
    private var firebaseLinkSection: some View {
        HStack {
            Button {
                openURL(URL(string: urlFirebaseConsole)!)
            } label: {
                HStack {
                    Image("firebase.logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.trailing, 2.0)
                        .frame(width: 22, height: 22)
                    Text("Go To Firebase Console").foregroundColor(Color.blue)
                    Image(systemName: "link").foregroundColor(Color.blue)
                }
            }
        }
    }
    private var statisticsSection: some View {
        HStack {
            Button {
                showArduinoStatisticsView.toggle()
            } label: {
                HStack {
                    Image(systemName: "archivebox.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.trailing, 2.0)
                        .frame(width: 22, height: 22)
                        .foregroundColor(Color.gray)
                    Text("Lifetime Statistics").foregroundColor(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(Color.secondary)
                }
            }
        }
    }
}

struct SystemStatusView_Previews: PreviewProvider {
    static var previews: some View {
        SystemStatusView()
    }
}
