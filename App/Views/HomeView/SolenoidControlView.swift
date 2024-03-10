//
//  SolenoidControlView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 6/2/22.
//

import SwiftUI

struct SolenoidControlView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State var showSolenoidControl = false
    @StateObject private var firebaseSolenoidControl = FirebaseSolenoidControl()
    @StateObject private var firebaseViewModelValues = FirebaseViewModel()
    
    @State private var pondDepthFeetDidChange: Bool = false
    @State private var pondDepthInchesDidChange: Bool = false
    @State var lastWaterLevelValueFeet: Double? = nil
    @State var lastWaterLevelValueInches: Double? = nil
    
    var body: some View {
        VStack {
            headerSection
            Spacer()
            Toggle(isOn: $showSolenoidControl) {
                Image("WaterFaucetSymbol")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                Text("Fill Pond")
            }.alert(isPresented: $showSolenoidControl, content: {
                Alert(title: Text("Confirm Fill"), message: Text("Are you sure you would like to fill the pond?"), primaryButton: .default(Text("Yes"), action: {
                    showSolenoidControl = true
                }), secondaryButton: .destructive(Text("No"), action: {
                    showSolenoidControl = false
                }))
            })
            .toggleStyle(SwitchToggleStyle(tint: Color.theme.background))
            .onChange(of: showSolenoidControl) { newValue in
                //print("Solenoid Valve Toggled to: \(newValue)")
                firebaseSolenoidControl.uploadSolenoidPowerSignal(solenoidPowerState: showSolenoidControl ? "ON" : "OFF")
            }
            Text("The pond is currently filling...").font(.caption).foregroundColor(showSolenoidControl ? .secondary : Color.clear)
            Divider().padding()
            ForEach (firebaseViewModelValues.pondParameters, id: \.self) { parameter in
                VStack {
                    HStack {
                        let pondDepth: Double = 36 // 36 inches from bottom to sensor
                        let pondDepthInches = parameter.waterLevel.rounded(.down).truncatingRemainder(dividingBy: 12)
//                        let pondDepthFeet = (parameter.waterLevel.rounded(.down) - pondDepthInches) / 12
                        let pondDepthFeet = (pondDepth - pondDepthInches) / 12
                        Text("Current Pond Depth:")
                        ZStack {
                            Text("\(pondDepthFeet, specifier: "%.0f")").font(.title).bold()
                            RoundedRectangle(cornerRadius: 3).foregroundColor(pondDepthFeetDidChange ? Color.secondary.opacity(0.3) : Color.clear)
                        }.padding(.bottom, 5.0).frame(width: 20, height: 20)
                        Text("ft ,")
                        ZStack {
                            Text("\(pondDepthInches, specifier: "%.0f")").font(.title).bold()
                            RoundedRectangle(cornerRadius: 3).foregroundColor(pondDepthInchesDidChange ? Color.secondary.opacity(0.3) : Color.clear)
                        }.padding(.bottom, 5.0).frame(width: 20, height: 20)
                        Text("in.")
                    }
                    Text("(\(parameter.waterLevel, specifier: "%.1f") in)")
                        .font(.footnote).foregroundColor(Color.secondary)
                }
            }.onChange(of: firebaseViewModelValues.pondParameters) { newValue in
                let pondDepthInches = newValue[0].waterLevel.rounded(.down).truncatingRemainder(dividingBy: 12)
                let pondDepthFeet = (newValue[0].waterLevel.rounded(.down) - Double(pondDepthInches)) / 12
                if lastWaterLevelValueFeet == nil {
                    lastWaterLevelValueFeet = pondDepthFeet
                }
                if lastWaterLevelValueFeet != pondDepthFeet {
                    lastWaterLevelValueFeet = pondDepthFeet
                    withAnimation(.easeOut(duration: 0.5)) {
                        pondDepthFeetDidChange.toggle()
                        lastWaterLevelValueFeet = pondDepthFeet
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pondDepthFeetDidChange.toggle()
                    }
                }
                if lastWaterLevelValueInches == nil {
                    lastWaterLevelValueInches = pondDepthInches
                }
                if lastWaterLevelValueInches != pondDepthInches {
                    lastWaterLevelValueInches = pondDepthInches
                    withAnimation(.easeOut(duration: 0.5)) {
                        pondDepthInchesDidChange.toggle()
                        lastWaterLevelValueInches = pondDepthInches
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pondDepthInchesDidChange.toggle()
                    }
                }
            }
        Spacer()
        }.padding()
        .onAppear {
            showSolenoidControl = firebaseSolenoidControl.getCurrentSolenoidPowerState()
        }
    }
}

struct SolenoidControlView_Previews: PreviewProvider {
    static var previews: some View {
        SolenoidControlView()
    }
}

extension SolenoidControlView {
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
            Text("Solenoid Valve Control").font(.title2).bold()
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
}
