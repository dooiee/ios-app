//
//  FirebaseHomeView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/11/22.
//

import SwiftUI

struct CurrentTabKey: EnvironmentKey {
    static var defaultValue: Binding<FirebaseHomeView.Tab> = .constant(.home)
}
extension EnvironmentValues {
    var currentTab: Binding<FirebaseHomeView.Tab> {
        get { self[CurrentTabKey.self] }
        set { self[CurrentTabKey.self] = newValue }
    }
}
struct BackgroundBlurView: UIViewRepresentable{
  func makeUIView(context:Context) -> UIView{
     let view=UIVisualEffectView(effect:UIBlurEffect(style:.light))
     DispatchQueue.main.async{
        view.superview?.superview?.backgroundColor = .clear
     }
      return view
  }
    func updateUIView(_ uiView:UIView,context:Context){}
}

struct FirebaseHomeView: View {
    
    enum Tab {
            case home
            case temperature
            case waterLevel
            case pH
            case tds
            case turbidity
        }
    
    @State var selectTab: Tab = .home
    @State var offsetArduinoTab = CGSize.zero
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var vm: FirebaseDataService
    @StateObject private var viewModel = ViewModel()
    @StateObject private var firebaseViewModel = FirebaseViewModel()
    @StateObject private var firebaseDataRetreival = FirebaseDataRetreivalForInterval()
    @StateObject private var firebaseUploadData = FirebaseUploadData()
    @State var spinningDisc: Bool = false
    @State private var refresh = true
    @State var showHealthSheet: Bool = false
    @State private var listRowsVisible: Bool = true
    @State private var remoteControlsVisible: Bool = true
    @State private var showArduinoControl: Bool = false
    @State var showRFRemote: Bool = false
    @State var showRFRemote2: Bool = false
    @State var showSolenoidControl: Bool = false
    @State var parametersOutOfSpec: Int = 0
//    @State var selectTab: Int = 0
    @State var animateValueChange: Bool = false
    @State var isLoading: Bool = false
    
    @State var temperatureValueChanged: Bool = false
    @State var waterLevelValueChanged: Bool = false
    @State var turbidityValueChanged: Bool = false
    @State var tdsValueChanged: Bool = false
    @State var pHValueChanged: Bool = false
    
    let backgroundOpacityValue: Double = 0.5
    let rectangleHeight: CGFloat = 85
    let cornerRadius: CGFloat = 16
    let lastDayInterval: Int = 1_000*60*60*24
    
    let parameterLoadingOpacityValue: Double = 0.2
    let parameterLoadingBoxWidth: CGFloat = 40
    let parameterLoadingBoxHeight: CGFloat = 15
    let parameterLoadingScaleEffect: CGFloat = 1.05
    let parameterLoadingCornerRadius: CGFloat = 5
    let parameterLoadingBarDuration: Double = 1.2

    @State var lastTemperatureValueForOnChanged: Double? = nil
    @State var lastWaterLevelValueForOnChanged: Double? = nil
    @State var lastTurbidityValueForOnChanged: Int? = nil
    @State var lastTDSValueForOnChanged: Int? = nil
    @State var lastpHValueForOnChanged: Double? = nil
    
    @State var waterOutOfSpec: Bool = false
    @State var recordRotationAngleValue: Angle = Angle(degrees: 0)
    
    var body: some View {
        TabView(selection: $selectTab) {
            VStack (spacing: 0) {
                headerSection
                ZStack { // for main section
                    LinearGradient(colors: colorScheme == .light ? [Color.theme.background.opacity(backgroundOpacityValue), Color.theme.background.opacity(backgroundOpacityValue/2)] : [Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                    ScrollView {
                        sensorDataSection
                            .onAppear {
                                withAnimation(.easeInOut(duration: parameterLoadingBarDuration).repeatForever()) {
                                isLoading.toggle()
                                }
                            }
                            .onChange(of: firebaseViewModel.pondParameters) { newValue in
                                //MARK: Temperature
                                if lastTemperatureValueForOnChanged == nil {
                                    lastTemperatureValueForOnChanged = newValue[0].temperature
                                }
                                if lastTemperatureValueForOnChanged != newValue[0].temperature {
//                                    valueChanged.toggle()
                                    lastTemperatureValueForOnChanged = newValue[0].temperature
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        temperatureValueChanged.toggle()
                                        lastTemperatureValueForOnChanged = newValue[0].temperature
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        temperatureValueChanged.toggle()
                                    }
                                }
                                //MARK: Water Level
                                if lastWaterLevelValueForOnChanged == nil {
                                    lastWaterLevelValueForOnChanged = newValue[0].waterLevel
                                }
                                if lastWaterLevelValueForOnChanged != newValue[0].waterLevel {
                                    lastWaterLevelValueForOnChanged = newValue[0].waterLevel
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        waterLevelValueChanged.toggle()
                                        lastWaterLevelValueForOnChanged = newValue[0].waterLevel
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        waterLevelValueChanged.toggle()
                                    }
                                }
                                //MARK: Turbidity
                                if lastTurbidityValueForOnChanged == nil {
                                    lastTurbidityValueForOnChanged = newValue[0].turbidityValue
                                }
                                if lastTurbidityValueForOnChanged != newValue[0].turbidityValue {
                                    lastTurbidityValueForOnChanged = newValue[0].turbidityValue
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        turbidityValueChanged.toggle()
                                        lastTurbidityValueForOnChanged = newValue[0].turbidityValue
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        turbidityValueChanged.toggle()
                                    }
                                }
                                //MARK: TDS
                                if lastTDSValueForOnChanged == nil {
                                    lastTDSValueForOnChanged = newValue[0].totalDissolvedSolids
                                }
                                if lastTDSValueForOnChanged != newValue[0].totalDissolvedSolids {
                                    lastTDSValueForOnChanged = newValue[0].totalDissolvedSolids
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        tdsValueChanged.toggle()
                                        lastTDSValueForOnChanged = newValue[0].totalDissolvedSolids
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        tdsValueChanged.toggle()
                                    }
                                }
                                //MARK: pH
                                if lastpHValueForOnChanged == nil {
                                    lastpHValueForOnChanged = newValue[0].pH
                                }
                                if lastpHValueForOnChanged != newValue[0].pH {
                                    lastpHValueForOnChanged = newValue[0].pH
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        pHValueChanged.toggle()
                                        lastpHValueForOnChanged = newValue[0].pH
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        pHValueChanged.toggle()
                                    }
                                }
                            }
                        VStack {
                            if listRowsVisible {
                                lastUpdatedAtListRow.transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        pondControlSection
                    }
                }
                
            }//.tag(0) //changing to fix bug
                .tag(Tab.home).environment(\.currentTab, $selectTab)
            GenericDetailView(title: "Temperature", legendUnits: "\u{00B0}", accentColor: Color.theme.accent)//.tag(1)
                .tag(Tab.temperature).environment(\.currentTab, $selectTab)
            GenericDetailView(title: "Water Level", legendUnits: " in", accentColor: Color.theme.accentBabyBlue)//.tag(2)
                .tag(Tab.waterLevel).environment(\.currentTab, $selectTab)
            GenericDetailView(title: "pH", legendUnits: "", accentColor: Color.theme.accentGreen)//.tag(3)
                .tag(Tab.pH).environment(\.currentTab, $selectTab)
            GenericDetailView(title: "Total Dissolved Solids", legendUnits: " ppm", accentColor: Color.theme.accentPeach)//.tag(4)
                .tag(Tab.tds).environment(\.currentTab, $selectTab)
            GenericDetailView(title: "Turbidity", legendUnits: " NTU", accentColor: Color.theme.accentLavender)//.tag(5)
                .tag(Tab.turbidity).environment(\.currentTab, $selectTab)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .ignoresSafeArea(.all)
    }
}
                
struct FirebaseHomeView_Previews: PreviewProvider {
    static var previews: some View {
        FirebaseHomeView()
    }
}

extension FirebaseHomeView {
    
    private var headerSection: some View {
        ZStack (alignment: .top) { // for header
//            LinearGradient(colors: [Color.theme.background.opacity(0.8), Color.theme.background.opacity(backgroundOpacityValue)], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            LinearGradient(colors: colorScheme == .light ? [Color.theme.background.opacity(0.8), Color.theme.background.opacity(backgroundOpacityValue)] : [Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                HStack (alignment: .center) {
                    navigationBarRecordIcon
                    Spacer()
                    Text("Project Shangri-La")
                        .fontWeight(.bold)
                        .foregroundColor(Color.primary)
                    .font(.system(size: 20))
                    Spacer()
                    navigationBarHealthIconButtonSheet
                }
                .padding(.horizontal)
        }
        .frame(height: 60)
    }
    
    private var sensorDataSection: some View {
        VStack (alignment: .leading, spacing: 5.0) { // was 2 spacing
            //Spacer()
            HStack {
                Text("Sensor Data").font(.subheadline)
                    .foregroundColor(Color.secondary)
                    .bold()
                    .padding(5.0)
                Spacer()
                Image(systemName: "chevron.down.circle")
                    .font(.headline)
                    .foregroundColor(Color.theme.accent)
                    .rotationEffect(Angle(degrees: listRowsVisible ? 0 : -90))
                    .scaleEffect(listRowsVisible ? 1.4 : 1.2)
                    .padding(5)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            listRowsVisible.toggle()
                        }
                    }
            }
            .padding(.bottom, 5.0)
            
            if listRowsVisible {
                temperatureListRow.transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
                waterLevelListRow.transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
                turbidityListRow.transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
                tdsListRow.transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
                phListRow.transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
            }
        }.padding([.top, .leading, .trailing])
    }
    
    private var pondControlSection: some View {
        VStack (alignment: .leading, spacing: 5) {
            HStack {
                Text("Pond Control").font(.subheadline)
                    .foregroundColor(Color.secondary)
                    .bold()
                    .padding(5)
                Spacer()
                Image(systemName: "chevron.down.circle")
                    .font(.headline)
                    .foregroundColor(Color.theme.accent)
                    .rotationEffect(Angle(degrees: remoteControlsVisible ? 0 : -90))
                    .scaleEffect(remoteControlsVisible ? 1.4 : 1.2)
                    .padding(.bottom, 5)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            remoteControlsVisible.toggle()
                        }
                    }
            }
            HStack {
                if remoteControlsVisible {
                    Spacer()
                    Button(action: { showArduinoControl.toggle() } ,
                           label: {
                        ZStack (alignment: .center) {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: 75, height: 75)
                                .foregroundColor(colorScheme == .light ? Color.theme.background : Color.theme.accentNightModeGray)
                                .shadow(
                                    color: colorScheme == .light ? Color.white.opacity(0.3) : Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.105),
                                  radius: 1,
                                    x: colorScheme == .light ? -2 : -2,
                                    y: colorScheme == .light ? -2 : -2)
                                .shadow(
                                    color: colorScheme == .light ? Color.theme.background.opacity(0.6) : Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.594),
                                  radius: 2,
                                    x: colorScheme == .light ? 3 : 3,
                                    y: colorScheme == .light ? 2 : 3)
                            Image("arduino.uno.board4")
                                .resizable()
                                .scaledToFit()
                                .rotation3DEffect(Angle(degrees: 5), axis: (x: 2, y: 6, z: 2))
                                .shadow(radius: 3, x:-2, y:-3)
                                .padding(.all, 6.0)
                                .font(.system(size: 45).weight(.regular))
                                .frame(width: 75, height: 75)
                                .background(Color.clear)
                        } })
                    .withPressableStyle()
                    .fullScreenCover(isPresented: $showArduinoControl,
                                     content: { ArduinoControlView()
                            .background(BackgroundBlurView())
                            .offset(x: offsetArduinoTab.width)
                            .opacity(2 - Double(abs(offsetArduinoTab.width / 150)))
                            .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offsetArduinoTab = gesture.translation
                                    }
                            .onEnded { value in
                            if value.location.x - value.startLocation.x > 150 {
                                withAnimation(.spring()) { showArduinoControl.toggle() }
                                offsetArduinoTab = .zero
                            } else {
                                offsetArduinoTab = .zero
                            }
                        }
                    ) })
                    .transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
                    Spacer()
                    Button(action: { showRFRemote.toggle() } ,
                           label: {
                        ZStack (alignment: .center) {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: 75, height: 75)
                                .foregroundColor(colorScheme == .light ? Color.theme.background : Color.theme.accentNightModeGray)
                                .shadow(
                                    color: colorScheme == .light ? Color.white.opacity(0.3) : Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.105),
                                  radius: 1,
                                    x: colorScheme == .light ? -2 : -2,
                                    y: colorScheme == .light ? -2 : -2)
                                .shadow(
                                    color: colorScheme == .light ? Color.theme.background.opacity(0.6) : Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.594),
                                  radius: 2,
                                    x: colorScheme == .light ? 3 : 3,
                                    y: colorScheme == .light ? 2 : 3)
                            Image(systemName: "water.waves").foregroundStyle(Color.blue.opacity(0.6)).font(.system(size: 50).weight(.regular)).offset(x:-4, y: -10).shadow(radius: 3, x:-3, y:-3).rotationEffect(Angle(degrees: 0))
                            Image(systemName: "sprinkler.and.droplets", variableValue: 0.6).foregroundStyle(colorScheme == .light ? Color.black : Color.gray, Color.yellow).font(.system(size: 30).weight(.regular)).offset(x:-8, y: -5).shadow(radius: 3, x:-3, y:-3)
                            Image(systemName: "fish.fill", variableValue: 0.6).foregroundStyle(Color.theme.accentPeach).font(.system(size: 15).weight(.regular)).offset(x:-19, y: 9).shadow(radius: 3, x:-3, y:-3).rotationEffect(Angle(degrees: -180))
                            Image(systemName: "wave.3.right")
                                .font(.system(size: 15).weight(.regular)).foregroundColor(colorScheme == .light ? Color.black.opacity(0.5) : Color.gray).shadow(radius: 5)
                                .rotationEffect(Angle(degrees: -120))
                                .offset(x:15, y:12)
                            Image(systemName: "av.remote.fill").foregroundColor(colorScheme == .light ? Color.black.opacity(0.7) : Color.gray).shadow(radius: 3, x: 2, y: -3)
                                .font(.system(size: 15).weight(.regular))
                                .offset(x:5,y:35)
                                .rotationEffect(Angle(degrees: -35))
                                //.frame(width: 75, height: 75)
                                .background(Color.clear)
                        } })
                    .withPressableStyle()
                    .fullScreenCover(isPresented: $showRFRemote, content: { RFRemoteView(powerState: firebaseUploadData.getCurrentRFPowerState()) })
                    .transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
                    Spacer()
                    Button(action: { showRFRemote2.toggle()
                         } ,
                           label: {
                        ZStack (alignment: .center) {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: 75, height: 75)
                                .foregroundColor(colorScheme == .light ? Color.theme.background : Color.theme.accentNightModeGray)
                                .shadow(
                                    color: colorScheme == .light ? Color.white.opacity(0.3) : Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.105),
                                  radius: 1,
                                    x: colorScheme == .light ? -2 : -2,
                                    y: colorScheme == .light ? -2 : -2)
                                .shadow(
                                    color: colorScheme == .light ? Color.theme.background.opacity(0.6) : Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.594),
                                  radius: 2,
                                    x: colorScheme == .light ? 3 : 3,
                                    y: colorScheme == .light ? 2 : 3)
                            Text("⛩").font(.system(size: 45).weight(.regular)).offset(x: -8, y: -11).shadow(color: colorScheme == .light ? Color.pink.opacity(0.3) : Color.gray.opacity(0.4), radius: colorScheme == .light ? 3 : 2, x: colorScheme == .light ? -3 : 2, y: colorScheme == .light ? -3 : -1).rotationEffect(Angle(degrees: -1))
                            Image(systemName: "wave.3.right")
                                .font(.system(size: 15).weight(.regular)).foregroundColor(colorScheme == .light ? Color.black.opacity(0.5) : Color.gray).shadow(radius: 5)
                                .rotationEffect(Angle(degrees: -120))
                                .offset(x:15, y:12)
                            Image(systemName: "av.remote.fill").foregroundColor(colorScheme == .light ? Color.black.opacity(0.7) : Color.gray).shadow(radius: 3, x: 2, y: -3)
                                .font(.system(size: 15).weight(.regular))
                                .offset(x:5,y:35)
                                .rotationEffect(Angle(degrees: -35))
                                //.frame(width: 75, height: 75)
                                .background(Color.clear)
                        } })
                    .withPressableStyle()
                    .fullScreenCover(isPresented: $showRFRemote2, content: { FirebaseTemperatureDetailViewChart() })
                    .transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
                    Spacer()
                    Button(action: { showSolenoidControl.toggle()
                         } ,
                           label: {
                        ZStack (alignment: .center) {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                //.frame(width: 75, height: 75)
                                .foregroundColor(colorScheme == .light ? Color.theme.background : Color.theme.accentNightModeGray)
                                .shadow(
                                    color: colorScheme == .light ? Color.white.opacity(0.3) : Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.105),
                                  radius: 1,
                                    x: colorScheme == .light ? -2 : -2,
                                    y: colorScheme == .light ? -2 : -2)
                                .shadow(
                                    color: colorScheme == .light ? Color.theme.background.opacity(0.6) : Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.594),
                                  radius: 2,
                                    x: colorScheme == .light ? 3 : 3,
                                    y: colorScheme == .light ? 2 : 3)
                            Image("WaterFaucetSymbol")
                                .resizable()
                                //.frame(width: 50.0, height: 50.0)
                                .scaledToFit()
                                .font(.system(size: 40).weight(.regular))
                                //.frame(width: 75, height: 75)
                                .background(Color.clear)
                        }.frame(width: 75, height: 75) })
                    .withPressableStyle()
                    .fullScreenCover(isPresented: $showSolenoidControl, content: { SolenoidControlView() })
                    .transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale))
                    Spacer()
                }
            }
            .padding(.top, 5.0)
            
        }.padding([.top, .leading, .trailing])
    }
    
    private var temperatureListRow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius).frame(height: rectangleHeight).foregroundColor(colorScheme == .light ? Color.white : Color.theme.accentNightModeGray).frame(maxWidth: .infinity)
            HStack {
                Button(action: { selectTab = .temperature } ,
                       label: { FirebaseListRowViewIcon(parameterIcon: "custom.thermometer.sun.fill-1", customIcon: true) })
                    .withPressableStyle()
                    .padding(.trailing, 3.0)
                FirebaseListRowViewTitle(parameterTitle: "Temperature")
                Spacer()
                ZStack {
                    if firebaseViewModel.pondParameters.isEmpty {
                        sensorDataValueLoadingAnimation
                    }
                    ForEach (firebaseViewModel.pondParameters, id: \.self) { parameter in
                        ZStack {
                            Text("\(parameter.temperature, specifier: "%.1f")")
//                            Text("\(parameter.temperature, specifier: "%.1f")\u{00B0}") // commented out one with degrees symbol
                                .font(.headline).foregroundColor(Color.primary)
                            RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(temperatureValueChanged ? Color.secondary.opacity(0.3) : Color.clear)
                        }
                    }
                    //.padding()
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(Color.clear)
                    Text("\u{00B0}F     ").font(.headline).foregroundColor(Color.primary).offset(x: -5)
                }
            }
            .padding([.leading, .trailing], 12)
        }
    }
    
    private var waterLevelListRow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius).frame(height: rectangleHeight).foregroundColor(colorScheme == .light ? Color.white : Color.theme.accentNightModeGray).frame(maxWidth: .infinity)
            HStack {
                Button { selectTab = .waterLevel } label: {
                    FirebaseListRowViewIcon(parameterIcon: "humidity.fill")
                }
                .withPressableStyle()
                .padding(.trailing, 3.0)
                FirebaseListRowViewTitle(parameterTitle: "Pond Depth")
                Spacer()
                ZStack {
                    if firebaseViewModel.pondParameters.isEmpty {
                        sensorDataValueLoadingAnimation
                    }
                    ForEach (firebaseViewModel.pondParameters, id: \.self) { parameter in
                        ZStack {
                            Text("\(parameter.waterLevel, specifier: "%.1f")")
                                .font(.headline).foregroundColor(Color.primary)
                            RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(waterLevelValueChanged ? Color.secondary.opacity(0.3) : Color.clear)
                        }
                    }
//                    .padding()
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(Color.clear)
                    Text("in    ").font(.headline).foregroundColor(Color.primary).offset(x: -5)
                }
            }
            .padding([.leading, .trailing], 12)
        }
    }
    
    private var turbidityListRow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius).frame(height: rectangleHeight).foregroundColor(colorScheme == .light ? Color.white : Color.theme.accentNightModeGray).frame(maxWidth: .infinity)
            HStack {
                Button { selectTab = .turbidity } label: {
                    FirebaseListRowViewIcon(parameterIcon: "cloud.rain.fill")
                }
                .withPressableStyle()
                .padding(.trailing, 3.0)
                if firebaseViewModel.pondParameters.isEmpty {
                    FirebaseListRowViewTitle(parameterTitle: "Turbidity", parameterSubtitle: "")
                }
                else {
                    ForEach (firebaseViewModel.pondParameters, id: \.self) { parameter in
                        FirebaseListRowViewTitle(parameterTitle: "Turbidity", parameterSubtitleDouble: parameter.turbidityVoltage, parameterSubtitleDoubleUnits: "V")
                    }
                }
                Spacer()
                ZStack {
                    if firebaseViewModel.pondParameters.isEmpty {
                        sensorDataValueLoadingAnimation
                    }
                    ForEach (firebaseViewModel.pondParameters, id: \.self) { parameter in
                        ZStack {
                            Text("\(parameter.turbidityValue)")
                                .font(.headline).foregroundColor(Color.primary)
                            RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(turbidityValueChanged ? Color.secondary.opacity(0.3) : Color.clear)
                        }
                    }
                    //.padding()
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(Color.clear)
                    Text("NTU").font(.headline).foregroundColor(Color.primary).offset(x: -5)
                }
            }
            .padding([.leading, .trailing], 12)
        }
    }
    
    private var tdsListRow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius).frame(height: rectangleHeight).foregroundColor(colorScheme == .light ? Color.white : Color.theme.accentNightModeGray).frame(maxWidth: .infinity)
            HStack {
                Button { selectTab = .tds } label: {
                    FirebaseListRowViewIcon(parameterIcon: "allergens")
                }
                .withPressableStyle()
                .padding(.trailing, 3.0)
                FirebaseListRowViewTitle(parameterTitle: "TDS", parameterSubtitle: "Total Dissolved Solids")
                Spacer()
                ZStack {
                    if firebaseViewModel.pondParameters.isEmpty {
                        sensorDataValueLoadingAnimation
                    }
                    ForEach (firebaseViewModel.pondParameters, id: \.self) { parameter in
                        ZStack {
                            Text("\(parameter.totalDissolvedSolids)")
                                .font(.headline).foregroundColor(Color.primary)
                            RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(tdsValueChanged ? Color.secondary.opacity(0.3) : Color.clear)
                        }
                    }
                    //.padding()
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(Color.clear)
                    Text("ppm").font(.headline).foregroundColor(Color.primary).offset(x: -5)
                }
            }
            .padding([.leading, .trailing], 12)
        }
    }
    
    private var phListRow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius).frame(height: rectangleHeight).foregroundColor(colorScheme == .light ? Color.white : Color.theme.accentNightModeGray).frame(maxWidth: .infinity)
            HStack {
                Button { selectTab = .pH } label: {
                    FirebaseListRowViewIcon(parameterIcon: "ivfluid.bag")
                }
                .withPressableStyle()
                .padding(.trailing, 3.0)
                FirebaseListRowViewTitle(parameterTitle: "pH", parameterSubtitle: "Potential Hydrogen")
                Spacer()
                ZStack {
                    if firebaseViewModel.pondParameters.isEmpty {
                        sensorDataValueLoadingAnimation
                    }
                    ForEach (firebaseViewModel.pondParameters, id: \.self) { parameter in
                        ZStack {
                            Text("\(parameter.pH, specifier: "%.1f")")
                                .font(.headline).foregroundColor(Color.primary)
                            RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(pHValueChanged ? Color.secondary.opacity(0.3) : Color.clear)
                        }
                    }
                    //.padding()
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 3).frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight).foregroundColor(Color.clear)
                }
            }
            .padding([.leading, .trailing], 12)
        }
    }
    
    private var sensorDataValueLoadingAnimation: some View {
        ZStack (alignment: .leading) {
            RoundedRectangle(cornerRadius: parameterLoadingCornerRadius)
                .foregroundColor(Color.secondary)
                .frame(width: parameterLoadingBoxWidth, height: parameterLoadingBoxHeight)
                .opacity(isLoading ? parameterLoadingOpacityValue : parameterLoadingOpacityValue + 0.1)
                .scaleEffect(isLoading ? parameterLoadingScaleEffect : 1.0)
            RoundedRectangle(cornerRadius: parameterLoadingCornerRadius)
                .foregroundColor(Color.secondary)
                .frame(width: isLoading ? parameterLoadingBoxWidth : 0, height: parameterLoadingBoxHeight)
                .opacity(isLoading ? parameterLoadingOpacityValue : parameterLoadingOpacityValue - 0.1)
                .scaleEffect(isLoading ? parameterLoadingScaleEffect : 1.0)
        }
    }
    
    private var lastUpdatedAtListRow: some View {
        ZStack {
            Text("Last updated \(Date().addingTimeInterval(0), style: .relative) ago")
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .font(.caption2)
                .padding(5)
        }
    }
    
    private var navigationBarHealthIconButtonSheet: some View {
        Button(action: {showHealthSheet.toggle()}) {
            ZStack {
                Image(systemName: "heart.text.square.fill")
                    .imageScale(.medium)
                    .symbolRenderingMode(colorScheme == .light ? .hierarchical : .palette)
                    .foregroundStyle(Color.red, colorScheme == .light ? Color.white.opacity(0.9) : Color.theme.accentNightModeGray)
                    .shadow(color: Color.white.opacity(0.4), radius: colorScheme == .light ? 0 : 3, x: 2, y: 2)
                    .font(.system(size: 40).weight(.regular))
                //TODO: add if command/bool to say appear if parameter is out of spec
                ForEach(firebaseViewModel.pondParameters) { pondParameter in
                    if pondParameter.temperature < 50 || pondParameter.temperature > 80 {
                        Image("custom.exclamationmark.triangle")
                            .renderingMode(.original)
                            .imageScale(.small)
                            .font(.system(size: 25).weight(.regular))
                            .offset(x: 13, y: 9)
                    }
                    else if pondParameter.waterLevel < 5 || pondParameter.waterLevel > 10 {
                        Image("custom.exclamationmark.triangle")
                            .renderingMode(.original)
                            .imageScale(.small)
                            .font(.system(size: 25).weight(.regular))
                            .offset(x: 13, y: 9)
                    }
                    else if pondParameter.turbidityValue > 1500 {
                        Image("custom.exclamationmark.triangle")
                            .renderingMode(.original)
                            .imageScale(.small)
                            .font(.system(size: 25).weight(.regular))
                            .offset(x: 13, y: 9)
                    }
                    else if pondParameter.totalDissolvedSolids > 400 {
                        Image("custom.exclamationmark.triangle")
                            .renderingMode(.original)
                            .imageScale(.small)
                            .font(.system(size: 25).weight(.regular))
                            .offset(x: 13, y: 9)
                    }
                    else if pondParameter.pH < 6.5 || pondParameter.pH > 8.5 {
                        Image("custom.exclamationmark.triangle")
                            .renderingMode(.original)
                            .imageScale(.small)
                            .font(.system(size: 25).weight(.regular))
                            .offset(x: 13, y: 9)
                    }
                } // ForEach
            } // ZStack
        } // Button
        .sheet(isPresented: $showHealthSheet, content: {
            HealthSheet()
        })
    }
    
    private var navigationBarRecordIcon: some View {
        Button(action: { withAnimation(.easeInOut(duration: 3.0)) {
            spinningDisc.toggle()
        }} ) {
            Image("appicon.inapp")
                .resizable()
                .frame(width: 50.0, height: 50.0)
                .scaledToFit()
                .rotationEffect(recordRotationAngleValue, anchor: .center)
                .shadow(color: Color.white.opacity(0.5), radius: colorScheme == .light ? 0 : 3, x: -1, y: 1)
                .gesture(
                    TapGesture()
                        .onEnded { value in
                            withAnimation(.easeInOut(duration: 3.0)) {
//                                angle += Angle(degrees: 2880)
                                recordRotationAngleValue = Angle(degrees: 2880)
                            }
                            recordRotationAngleValue = Angle(degrees: 0)
                        }
                )
        } // Button
    }
}

struct HealthSheet: View {
    
    @State var parametersOutOfSpec: Int = 4
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack (alignment: .top) {
            Color.theme.background.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Spacer()
                    Button { presentationMode.wrappedValue.dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(25)
                    }
                }
                Text("Current Pond Health...")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .font(.title)
                Text(parametersOutOfSpec >= 3 ? "GOOD" : "POOR")
                    .fontWeight(.heavy)
                    .foregroundColor(parametersOutOfSpec >= 3 ? Color.theme.batteryGreen : Color.theme.batteryYellow)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 60))
                    
                ZStack (alignment: .top) {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color.red)
                    Image(systemName: "heart.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(parametersOutOfSpec >= 3 ? Color.theme.batteryGreen : Color.theme.batteryYellow)
                        .overlay {
                            GeometryReader { geometry in
                                ZStack {
                                    Rectangle()
                                        .foregroundColor(Color.gray)
                                        .frame(height: (5 - CGFloat(parametersOutOfSpec)) / 5 * geometry.size.height)
                                }
                            }
                        }
                        .mask {
                            Image(systemName: "bolt.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding([.leading, .bottom])
                        }
                }
                Text("You have \(5 - parametersOutOfSpec) parameter(s) out of spec:")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(5)
                
                Text("- Water Level")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
//            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

extension View {
    func withPressableStyle() -> some View {
        buttonStyle(PressableButtonStyle())
    }
}
