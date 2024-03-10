//
//  RFRemoteView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 4/1/22.
//

import SwiftUI

struct RFRemoteView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var firebaseUploadData = FirebaseUploadData()
    @State var powerState: Bool
    @State private var signalLED: Bool = false
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: nil, alignment: nil),
        GridItem(.flexible(), spacing: nil, alignment: nil),
        GridItem(.flexible(), spacing: nil, alignment: nil)]

    let rfRemoteColors: [Color] = [.clear, .gray, .clear, .orange, .orange, .orange, .orange, .white, .orange, .red, .green, .blue, .orange, .green.opacity(0.7), .cyan, .orange.opacity(0.5), .cyan.opacity(0.6), .purple, .yellow, .teal, .pink.opacity(0.7)]
    
    let rfOnCode = "111111111111111100000001"
    let rfOffCode = "111111111111111100000011"
    let rfRed = "000001010001110000001010"
    
    let horizontalButtonPadding = 9.0
    
    ///// This is the correct strings for underwater LEDS
    //FIXME: update correct signals with string/decimal array for underwater LEDS
    let rfSignals: [String] = ["", "000001010001110000000011", "", "", "", "", "", "000001010001110000001000", "", "000001010001110000001010", "000001010001110000001011", "000001010001110000001100", "000001010001110000001101", "000001010001110000001110", "000001010001110000001111", "000001010001110000010000", "000001010001110000010001", "000001010001110000010010", "000001010001110000010011", "000001010001110000010100", "000001010001110000010101"]
    
    let rfDecimalSignals: [Int] = [0, 0, 0, 0, 334855, 334856, 334849, 334856, 16776964, 334858, 334859, 334860, 334861, 334862, 334863, 334864, 334865, 334866, 334867, 334868, 334869] // (24Bit)
    
    ///// Below is all transmitted codes for the underwater LED RF remote.
    let wiredLEDRFRemoteButtonFunctions: [String] = ["Brightness", "Sleep Timer", "Power", "4H", "8H", "12H", "Flash", "White", "Fade", "Red", "Green", "Blue", "Orange", "Sea-Green", "Teal", "Orange-Yellow", "Cyan", "Indigo", "Yellow", "Azure", "Magenta"]
    let wiredLEDRFRemoteBinarySignals: [String] =
    ["000001010001110000000001", "000001010001110000000010", "000001010001110000000011", "000001010001110000000100", "000001010001110000000101", "000001010001110000000110", "000001010001110000000111", "000001010001110000001000", "000001010001110000001001", "000001010001110000001010", "000001010001110000001011", "000001010001110000001100", "000001010001110000001101", "000001010001110000001110", "000001010001110000001111", "000001010001110000010000", "000001010001110000010001", "000001010001110000010010", "000001010001110000010011", "000001010001110000010100", "000001010001110000010101"]
    let wiredLEDRFRemoteDecimalSignals: [Int] = [334849, 334850, 334851, 334852, 334853, 334854, 334855, 334856, 334857, 334858, 334859, 334860, 334861, 334862, 334863, 334864, 334865, 334866, 334867, 334868, 334869] // (24Bit)
    let wiredLEDRFRemoteTriStateSignals: [String] =
    ["00FF0F10000F", "N/A", "00FF0F100001", "00FF0F1000F0", "00FF0F1000FF", "N/A", "00FF0F1000F1", "N/A", "N/A", "N/A", "N/A", "00FF0F100010", "00FF0F10001F", "N/A", "00FF0F100011", "00FF0F100F00", "00FF0F100F0F", "N/A", "00FF0F100F01", "00FF0F100FF0", "00FF0F100FFF"]
    
    ///// Below is all transmitted codes for the battery powered round LED RF remote.
    let wirelessLEDRFRemoteButtonFunctions: [String] = ["On", "Time Off", "Off", "Brightness Up", "Flash", "Fade", "Brightness Down", "Smooth", "White", "Red", "Green", "Blue", "Orange/Yellow", "Sea-Green/Teal", "Indigo/Magenta", "Star Fill Pattern", "Circle Fill Pattern", "Alternating Direction Fill Pattern", "2H", "4H", "6H"]
    let wirelessLEDRFRemoteBinarySignalsAllButtonCodes: [String] =
    ["111111111111111100000001", "111111111111111100000010", "111111111111111100000011", "111111111111111100000100", "111111111111111100000101", "111111111111111100000110", "111111111111111100000111", "111111111111111100001000", "111111111111111100001001", "111111111111111100001010", "111111111111111100001011", "111111111111111100001100", "111111111111111100001101 / 111111111111111110001101", "111111111111111100001110 / 111111111111111110001110", "111111111111111100001111 / 111111111111111110001111", "111111111111111100010000 / 111111111111111110010000", "111111111111111100010001 / 111111111111111110010001", "111111111111111100010010 / 111111111111111110010010", "111111111111111100010011", "111111111111111100010100", "111111111111111100010101"]
    let wirelessLEDRFRemoteDecimalSignalsAllButtonCodes: [Int] = [16776961, 16776962, 16776963, 16776964, 16776965, 16776966, 16776967, 16776968, 16776969, 16776970, 16776971, 16776972, 16776973 / 16777101, 16776974 / 16776974, 16776975 / 16777103, 16776976 / 16777104, 16776977 / 16777105, 16776978 / 16777106, 16776979, 16776980, 16776981] // (24Bit)
    let wirelessLEDRFRemoteTriStateSignalsAllButtonCodes: [String] =
    ["11111111000F", "N/A", "111111110001", "1111111100F0", "1111111100FF", "N/A", "1111111100F1", "N/A", "N/A", "N/A", "N/A", "111111110010", "11111111001F / N/A", "N/A / N/A", "111111110011 / N/A", "111111110F00 / N/A", "111111110F0F / N/A", "N/A / N/A", "111111110F01", "111111110FF0", "111111110FFF"]
    
    ///// Spliting up arrays for the buttons with two signal codes, then adding a terinary operator to choose which code to send based on one currently uploaded to firebase/whichever one is toggled based on variable in workspace.
    //Signal Code - Top Option
    let wirelessLEDRFRemoteBinarySignalsButtonCodeFirstOption: [String] =
    ["111111111111111100000001", "111111111111111100000010", "111111111111111100000011", "111111111111111100000100", "111111111111111100000101", "111111111111111100000110", "111111111111111100000111", "111111111111111100001000", "111111111111111100001001", "111111111111111100001010", "111111111111111100001011", "111111111111111100001100", "111111111111111100001101", "111111111111111100001110", "111111111111111100001111", "111111111111111100010000", "111111111111111100010001", "111111111111111100010010", "111111111111111100010011", "111111111111111100010100", "111111111111111100010101"]
    let wirelessLEDRFRemoteDecimalSignalsButtonCodeFirstOption: [Int] = [16776961, 16776962, 16776963, 16776964, 16776965, 16776966, 16776967, 16776968, 16776969, 16776970, 16776971, 16776972, 16776973, 16776974, 16776975, 16776976, 16776977, 16776978, 16776979, 16776980, 16776981] // (24Bit)
    let wirelessLEDRFRemoteTriStateSignalsButtonCodeFirstOption: [String] =
    ["11111111000F", "N/A", "111111110001", "1111111100F0", "1111111100FF", "N/A", "1111111100F1", "N/A", "N/A", "N/A", "N/A", "111111110010", "11111111001F", "N/A", "111111110011", "111111110F00", "111111110F0F", "N/A / N/A", "111111110F01", "111111110FF0", "111111110FFF"]
    
    //Signal Code - Bottom Option
    let wirelessLEDRFRemoteBinarySignalsButtonCodeSecondOption: [String] =
    ["111111111111111100000001", "111111111111111100000010", "111111111111111100000011", "111111111111111100000100", "111111111111111100000101", "111111111111111100000110", "111111111111111100000111", "111111111111111100001000", "111111111111111100001001", "111111111111111100001010", "111111111111111100001011", "111111111111111100001100", "111111111111111110001101", "111111111111111110001110", "111111111111111110001111", "111111111111111110010000", "111111111111111110010001", "111111111111111110010010", "111111111111111100010011", "111111111111111100010100", "111111111111111100010101"]
    let wirelessLEDRFRemoteDecimalSignalsButtonCodeSecondOption: [Int] = [16776961, 16776962, 16776963, 16776964, 16776965, 16776966, 16776967, 16776968, 16776969, 16776970, 16776971, 16776972, 16777101, 16777102, 16777103, 16777104, 16777105, 16777106, 16776979, 16776980, 16776981] // (24Bit)
    let wirelessLEDRFRemoteTriStateSignalsButtonCodeSecondOption: [String] =
    ["11111111000F", "N/A", "111111110001", "1111111100F0", "1111111100FF", "N/A", "1111111100F1", "N/A", "N/A", "N/A", "N/A", "111111110010", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A / N/A", "111111110F01", "111111110FF0", "111111110FFF"]
    
    var body: some View {
        ZStack {
            colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
            VStack (alignment: .center) {
                rfSignalLED
                Spacer()
                rfControllerButtons
                Spacer()
            }
        }
    }
}

extension RFRemoteView {
    
    private var rfSignalLED: some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(colorScheme == .light ? Color.black : Color.secondary)
                    .font(.title)
                    .offset(y:15)
                    .padding()
            }
            Spacer()
            ZStack {
                Circle()
                    .foregroundColor(signalLED ? Color.red : Color.red.opacity(colorScheme == .light ? 0.1 : 0.5))
                Circle()
                    .stroke(Color.black, lineWidth: 2)
            }.offset(x: 0, y: -13)
                .padding(.bottom, 4.0)
                .frame(height: 36.0)
            Spacer()
            Button {} label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.clear)
                    .font(.title)
                    .padding()
            }
        }.padding(.top)
    }
    
    private var rfControllerButtons: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(rfRemoteColors.indices, id: \.self) { index in
                Button { if rfSignals[index] != "" {
                    firebaseUploadData.uploadRFColorCode(rfCode: rfSignals[index], color: rfRemoteColors[index])
                    firebaseUploadData.uploadRFColorCodeDecimal(rfCode: rfDecimalSignals[index], color: rfRemoteColors[index])
                    HapticManager.instance.impact(style: .soft)
                    self.signalLED.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            self.signalLED.toggle()
                        }
                    }
                } } label: {
                    ZStack {
                        Circle()
                            .foregroundColor(rfRemoteColors[index]).padding(.horizontal, horizontalButtonPadding)
                        // commented out b/c overlay made button actions unusable.
//                            .overlay(Circle().stroke(index == 0 || index == 2 ? Color.clear : Color.black, lineWidth: 3))
                        if index == 6 || index == 8 {
                            Image(systemName: index == 6 ? "sunrise": "sunset")
                                .font(.system(size: 40).weight(.bold)).foregroundColor(Color.black)
                                .onTapGesture {
                                    firebaseUploadData.uploadRFColorCodeDecimal(rfCode: rfDecimalSignals[index], color: rfRemoteColors[index])
//                                    firebaseUploadData.uploadRFColorCodeDecimal(rfCode: rfDecimalSignals[index], color: rfRemoteColors[index])
                                    HapticManager.instance.impact(style: .soft)
                                    self.signalLED.toggle()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        withAnimation {
                                            self.signalLED.toggle()
                                        }
                                    }
                                }.padding(.bottom, 8.0)
                        }
                        Circle()
                            .stroke(index == 0 || index == 2 ? Color.clear : colorScheme == .light ? Color.black : Color.secondary, lineWidth: 3).padding(.horizontal, horizontalButtonPadding)
                            //.frame(height: UIScreen.main.bounds.height/9)
                            .onTapGesture {
                                self.signalLED.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation {
                                        self.signalLED.toggle()
                                    }
                                }
                            }
                        if index == 1 {
                            ZStack {
                                Circle()
                                    .foregroundColor(Color.gray)
                                    .padding(.horizontal, horizontalButtonPadding)
                                    .overlay(Circle().stroke(self.powerState == true ? Color.theme.batteryGreen : colorScheme == .light ? Color.black : Color.secondary, lineWidth: 3).padding(.horizontal, horizontalButtonPadding))
                                Image(systemName: "power")
                                    .font(.system(size: 35).weight(.semibold))
                                    .foregroundColor(powerState == true ? Color.theme.batteryGreen : Color.black)
                            }//.frame(height: UIScreen.main.bounds.height/9)
                                .onTapGesture {
                                    HapticManager.instance.impact(style: .soft)
                                    self.powerState.toggle()
                                    powerState == true ? firebaseUploadData.uploadRFPowerSignal(rfPowerState: rfOnCode) : firebaseUploadData.uploadRFPowerSignal(rfPowerState: rfOffCode)
                                    self.signalLED.toggle()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        withAnimation {
                                            self.signalLED.toggle()
                                        }
                                    }
                                }
                        }
                    } // ZStack
                } // label
            } // ForEach
            .onAppear {
                if powerState == false {
                    powerState = firebaseUploadData.getCurrentRFPowerState()
                }
            }
        } // LazyVGrid
        .padding(.horizontal)
        .padding(.bottom, 35)
    }
}

struct RFRemoteView_Previews: PreviewProvider {
    static var previews: some View {
        RFRemoteView(powerState: true)
    }
}
