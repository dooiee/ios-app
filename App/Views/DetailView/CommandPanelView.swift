//
//  FirebaseTemperatureDetailView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/13/22.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, @ViewBuilder content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
}

//protocol CommandPanelListRowTemplate: View {}

//struct CustomCommandPanelListRow<Content: View>: CommandPanelListRowTemplate {
//    let content: () -> Content
//
//    init(@ViewBuilder content: @escaping () -> Content) {
//        self.content = content
//    }
//
//    var body: some View {
//        HStack {
//            content()
//        }
//    }
//}


struct CustomCommandPanelSection: View {
    let text: String
    let imageName: String?
    let symbolRenderingMode: SymbolRenderingMode?
    let primaryColor: Color?
    let secondaryColor: Color?
    let tertiaryColor: Color?
    let toggleButtonColor: Color?
    let alertTitle: String?
    let alertMessage: String?
    let alertAction: (() -> Void)?
    
    let defaultImageString: String = "folder.badge.questionmark"
    let defaultAlertMessage: String = "Are you sure you would like to perform this command?"
    
    @State private var isToggled = false
//    @State private var commandSent = false
    @Binding var commandSent: Bool
//    @Binding var commandSentResponse: String? // Add commandSentResponse binding here
    
    var body: some View {
        Toggle(isOn: $isToggled) {
            HStack {
                if let imageName = imageName {
                    Image(systemName: imageName)
                        .symbolRenderingMode(symbolRenderingMode ?? .hierarchical)
                        .if(primaryColor != nil && secondaryColor == nil && tertiaryColor == nil) {
                            $0.foregroundColor(primaryColor!)
                        }
                        .if(primaryColor != nil && secondaryColor != nil && tertiaryColor == nil) {
                            $0.foregroundStyle(
                                primaryColor!,
                                secondaryColor!
                            )
                        }
                        .if(primaryColor != nil && secondaryColor != nil && tertiaryColor != nil) {
                            $0.foregroundStyle(
                                primaryColor!,
                                secondaryColor!,
                                tertiaryColor!
                            )
                        }
                        .imageScale(.large)
                        .padding(.trailing, 5.0)
                }
                Text(text)
                Spacer()
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: toggleButtonColor ?? Color.theme.background))
        .alert(isPresented: $isToggled, content: {
            Alert(title: Text(alertTitle ?? text), message: Text(alertMessage ?? defaultAlertMessage), primaryButton: .default(Text("Yes"), action: {
                self.commandSent = true
                alertAction?()
            }), secondaryButton: .destructive(Text("No"), action: {
                self.commandSent = false
            }))
        })
    }
}

struct FirebaseTemperatureDetailViewChart: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var vm: FirebaseDataService
    @StateObject private var fvm = FirebaseDataService()
    // ...
    @StateObject private var arduinoControl: ArduinoControlViaFirebase<LEDColorData>
    // ...
    
    @StateObject private var arduinoVM = ArduinoViewModel()
    
    @State var command = false
    @State var commandSent = false
    @State var test1CommandSent = false
    @State var colorCommandSent = false
    @State var commandSentResponse: String? // Define commandSentResponse here
    @State var statusCommandSent = false
    
    @State private var selectedColor: Color = Color.white
    @State private var isColorChanged = false
    
    init() {
        // 2. Initialize ControlPanelConfig and ArduinoControlViaFirebase with appropriate values
        let config = ControlPanelConfig(
            parentPath: "SystemStatus/Board/MKR_1010/OnBoardLED/Color",
            onBoardLEDColorRGBRedPath: "RGB/red",
            onBoardLEDColorRGBGreenPath: "RGB/green",
            onBoardLEDColorRGBBluePath: "RGB/blue",
            onBoardLEDColorBrightnessPath: "brightness",
            onBoardLEDColorLastUpdatedPath: "lastUpdated"
        )
        _arduinoControl = StateObject(wrappedValue: ArduinoControlViaFirebase<LEDColorData>(config: config))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
                List {
                    onBoardLED
                    fetchLEDStatusSection
                    firebaseSection
                    mqttSection
                    networkingSection
                    wifiSection
                    awsSection
                }
                .listStyle(.sidebar)
                .background(colorScheme == .light ? Color(red: 0.949, green: 0.949, blue: 0.97) : Color.black)
            }
            .onChange(of: commandSent, perform: { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        commandSent = false
                    }
                }
            })
            // On-Board LED Command Section //
            .onChange(of: colorCommandSent) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        colorCommandSent = false
                    }
                }
            }
            .onChange(of: test1CommandSent) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        test1CommandSent = false
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(colorScheme == .light ? Color.black : Color.secondary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Command Panel")
                        .font(.title2)
                        .bold()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add action here
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.clear)
                    }
                }
            }
        }
    }
}

extension FirebaseTemperatureDetailViewChart {
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
            Text("Command Panel").font(.title2).bold()
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
    private var commandListRow: some View {
        //        ForEach (firebaseArduinoControl.arduinoStatus, id: \.self) { parameter in
        Section(header: Text("Command"), footer:
                    HStack {
            Text(commandSent ? "Command Sent!" : "")
        })
        {
            Toggle(isOn: $command) {
                HStack {
                    Image(systemName: "icloud.and.arrow.up.fill").symbolRenderingMode(.palette).foregroundStyle(Color.red, Color("AccentColorPeach"))
                        .imageScale(.large).padding(.trailing, 5.0)
                    Text("Command:")
                    Spacer()
                }
            }
            .toggleStyle( SwitchToggleStyle(tint: Color.theme.background))
            .alert(isPresented: $command, content: {
                Alert(title: Text("Send Command {Command_Name}"), message: Text("Are you sure you would like to perform this command?"), primaryButton: .default(Text("Yes"), action: {
                    commandSent = true
                }), secondaryButton: .destructive(Text("No"), action: {
                    commandSent = false
                }))
            })
        }
//    } // ForEach
    }
    
    private var onBoardLED: some View {
        Section(header: Text("MKR On-Board RGB"), footer:
            HStack {
            Text(colorCommandSent ? commandSentResponse ?? "" : "")
            })
        {
            VStack {
                ColorPicker(selection: $selectedColor, supportsOpacity: true) {
                    HStack(alignment: .center, spacing: 5) {
                        Text("Color Picker")
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        Spacer()
                        VStack {
                            HStack {
                                Text("R:\(Int(selectedColor.rgbaComponents.red * 255))")
                                    .foregroundColor(.secondary)
                                .font(.caption).bold()
                                Text("G:\(Int(selectedColor.rgbaComponents.green * 255))")
                                    .foregroundColor(.secondary)
                                    .font(.caption).bold()
                                Text("B:\(Int(selectedColor.rgbaComponents.blue * 255))")
                                    .foregroundColor(.secondary)
                                    .font(.caption).bold()
                            }
                            Text("Brightness: \(Int(selectedColor.rgbaComponents.alpha * 100))%")
                                .foregroundColor(.secondary)
                                .font(.caption).bold()
                        }
                    }
                }
            }
            CustomCommandPanelSection(
                text: "Send Color to MKR 1010?",
                imageName: "light.beacon.max",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.blue,
                alertMessage: "Would you like to set the on-board MKR-1010 LED to the Color Picker color?",
                alertAction: {
                    arduinoControl.setOnBoardLEDColor(color: selectedColor) { success in
                        DispatchQueue.main.async {
                            commandSentResponse = success ? "Upload Successful!" : "Upload Error"
                        }
                    }
                },
                commandSent: $colorCommandSent
            )
        }
    }
    
    private var fetchLEDStatusSection: some View {
        Section(header: Text("Arduino LED Status"), footer: footerView) {
            Button(action: {
                arduinoVM.fetchLEDStatus()
                statusCommandSent = true // Set this to true once the button is pressed
            }) {
                HStack(alignment: .center, spacing: 5) {
                    if let status = arduinoVM.ledStatus {
                        Text("Status")
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        Spacer()
                        VStack {
                            HStack {
                                Text("R:\(status.red)")
                                    .foregroundColor(.secondary)
                                    .font(.caption).bold()
                                Text("G:\(status.green)")
                                    .foregroundColor(.secondary)
                                    .font(.caption).bold()
                                Text("B:\(status.blue)")
                                    .foregroundColor(.secondary)
                                    .font(.caption).bold()
                            }
                            Text("Intensity: \(status.intensity)")
                                .foregroundColor(.secondary)
                                .font(.caption).bold()
                        }.padding(.trailing, 5.0)
                        // Show the refresh button if StatusCommandSent is true
                        if statusCommandSent {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                    } else {
                        Text("Fetch LED Status")
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle()) // Apply borderless button style to make the entire row clickable without button-like appearance
        }
    }
    
    private var footerView: some View {
        Group {
            if let errorMessage = arduinoVM.ledStatusError {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                EmptyView()
            }
        }
    }
    
    private var firebaseSection: some View {
        Section(header: Text("Firebase"), footer:
                    HStack {
            Text(test1CommandSent ? "Command Sent!" : "")
        })
        {
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
        }
    }
    
    private var mqttSection: some View {
        Section(header: Text("MQTT"), footer:
                    HStack {
            Text(test1CommandSent ? "Command Sent!" : "")
        })
        {
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
        }
    }
    
    private var wifiSection: some View {
        Section(header: Text("Wi-Fi"), footer:
                    HStack {
            Text(test1CommandSent ? "Command Sent!" : "")
        })
        {
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
        }
    }
    
    private var networkingSection: some View {
        Section(header: Text("TCP/IP"), footer:
                    HStack {
            Text(test1CommandSent ? "Command Sent!" : "")
        })
        {
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
        }
    }
    private var awsSection: some View {
        Section(header: Text("AWS"), footer:
                    HStack {
            Text(test1CommandSent ? "Command Sent!" : "")
        })
        {
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
            CustomCommandPanelSection(
                text: "Testing",
                imageName: "iphone.radiowaves.left.and.right.circle",
                symbolRenderingMode: .palette,
                primaryColor: Color.blue,
                secondaryColor: Color.red,
                commandSent: $test1CommandSent
            )
        }
    }
}

struct FirebaseTemperatureDetailViewChart_Previews: PreviewProvider {
    static var previews: some View {
        FirebaseTemperatureDetailViewChart()
    }
}

extension CustomCommandPanelSection {
    init(text: String, imageName: String?, symbolRenderingMode: SymbolRenderingMode?, primaryColor: Color, secondaryColor: Color? = nil, tertiaryColor: Color? = nil, toggleButtonColor: Color? = nil, alertTitle: String? = nil, alertMessage: String? = nil, alertAction: (() -> Void)? = nil, commandSent: Binding<Bool>) {
        self.text = text
        self.imageName = imageName
        self.symbolRenderingMode = symbolRenderingMode
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
        self.toggleButtonColor = toggleButtonColor
        self.alertTitle = alertTitle ?? text
        self.alertMessage = alertMessage ?? defaultAlertMessage
        self.alertAction = alertAction
        self._commandSent = commandSent
    }
    
    init(text: String, imageName: String?, symbolRenderingMode: SymbolRenderingMode?, primaryColor: Color, secondaryColor: Color, tertiaryColor: Color? = nil, toggleButtonColor: Color? = nil, alertTitle: String? = nil, alertMessage: String? = nil, alertAction: (() -> Void)? = nil, commandSent: Binding<Bool>) {
        self.text = text
        self.imageName = imageName
        self.symbolRenderingMode = symbolRenderingMode
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
        self.toggleButtonColor = toggleButtonColor
        self.alertTitle = alertTitle ?? text
        self.alertMessage = alertMessage ?? defaultAlertMessage
        self.alertAction = alertAction
        self._commandSent = commandSent
    }
    
    init(text: String, imageName: String?, symbolRenderingMode: SymbolRenderingMode?, primaryColor: Color, secondaryColor: Color, tertiaryColor: Color, toggleButtonColor: Color? = nil, alertTitle: String? = nil, alertMessage: String? = nil, alertAction: (() -> Void)? = nil, commandSent: Binding<Bool>) {
        self.text = text
        self.imageName = imageName
        self.symbolRenderingMode = symbolRenderingMode
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
        self.toggleButtonColor = toggleButtonColor
        self.alertTitle = alertTitle ?? text
        self.alertMessage = alertMessage ?? defaultAlertMessage
        self.alertAction = alertAction
        self._commandSent = commandSent
    }

    init(text: String, imageName: String?, symbolRenderingMode: SymbolRenderingMode?, primaryColor: Color?, commandSent: Binding<Bool>) {
        self.text = text
        self.imageName = imageName
        self.symbolRenderingMode = symbolRenderingMode
        self.primaryColor = primaryColor
        self.secondaryColor = nil
        self.tertiaryColor = nil
        self.toggleButtonColor = nil
        self.alertTitle = text
        self.alertMessage = defaultAlertMessage
        self.alertAction = nil
        self._commandSent = commandSent
    }
    
    init(text: String, imageName: String, symbolRenderingMode: SymbolRenderingMode?, primaryColor: Color, secondaryColor: Color,
         commandSent: Binding<Bool>) {
        self.text = text
        self.imageName = imageName
        self.symbolRenderingMode = symbolRenderingMode
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = nil
        self.toggleButtonColor = nil
        self.alertTitle = text
        self.alertMessage = defaultAlertMessage
        self.alertAction = nil
        self._commandSent = commandSent
    }
    
    init(text: String, imageName: String?, symbolRenderingMode: SymbolRenderingMode?, primaryColor: Color, secondaryColor: Color, tertiaryColor: Color, commandSent: Binding<Bool>) {
        self.text = text
        self.imageName = imageName
        self.symbolRenderingMode = symbolRenderingMode
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
        self.toggleButtonColor = nil
        self.alertTitle = text
        self.alertMessage = defaultAlertMessage
        self.alertAction = nil
        self._commandSent = commandSent
    }
    
}
