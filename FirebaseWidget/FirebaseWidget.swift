//
//  FirebaseWidget.swift
//  FirebaseWidget
//
//  Created by Nick Doolittle on 8/30/22.
//

import WidgetKit
import SwiftUI
import Intents
import Foundation
import Firebase
import SwiftUICharts


struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), pondParameters: PondParameters(temperature: 72.3, totalDissolvedSolids: 275, turbidityValue: 3000, turbidityVoltage: 0.5, waterLevel: 12.2, pH: 7.5))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        getFirebasePondParameters { parameters in
            let entry = SimpleEntry(date: Date(), configuration: configuration, pondParameters: parameters)
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        getFirebasePondParameters { parameters in
            let entry = SimpleEntry(date: currentDate, configuration: configuration, pondParameters: parameters)
            
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
//            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
    var pondParameters = [PondParameters]()
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    func getFirebasePondParameters(completion: @escaping (PondParameters) -> ()) {
        let refPondParameters = Database.database().reference().child("Pond Parameters")
        
        refPondParameters.observe(.value, with: { (snapshot) in
                
            guard let value = snapshot.value as? [String: Any] else { return }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value)
                    let decodedPondParameters = try JSONDecoder().decode(PondParameters.self, from: jsonData)
                    completion(PondParameters(temperature: decodedPondParameters.temperature, totalDissolvedSolids: decodedPondParameters.totalDissolvedSolids, turbidityValue: decodedPondParameters.turbidityValue, turbidityVoltage: decodedPondParameters.turbidityVoltage, waterLevel: decodedPondParameters.waterLevel, pH: decodedPondParameters.pH))
                    print("Updated Widget at: \(Date().formatted())")
                } catch let error {
                    print("Error json parsing \(error)")
                }
            refPondParameters.removeAllObservers()
        }) // databaseHandle
    } // func
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let pondParameters: PondParameters?
}

struct PondParameters: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    let temperature: Double
    let totalDissolvedSolids, turbidityValue: Int
    let turbidityVoltage, waterLevel: Double
    let pH: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "Temperature"
        case totalDissolvedSolids = "Total Dissolved Solids"
        case turbidityValue = "Turbidity Value"
        case turbidityVoltage = "Turbidity Voltage"
        case waterLevel = "Water Level"
        case pH = "pH"
    }
}

class FirebaseViewModel: ObservableObject {
        
    @Published var pondParameters = [PondParameters]()
    
    init() {
        getFirebasePondParameters()
    }
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    
    func getFirebasePondParameters() {
        let refPondParameters = Database.database().reference().child("Pond Parameters")
        
        databaseHandle = refPondParameters.observe(.value, with: { (snapshot) in
                
            guard let value = snapshot.value as? [String: Any] else { return }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value)
                    let decodedPondParameters = try JSONDecoder().decode(PondParameters.self, from: jsonData)
                    self.pondParameters = [PondParameters(temperature: decodedPondParameters.temperature, totalDissolvedSolids: decodedPondParameters.totalDissolvedSolids, turbidityValue: decodedPondParameters.turbidityValue, turbidityVoltage: decodedPondParameters.turbidityVoltage, waterLevel: decodedPondParameters.waterLevel, pH: decodedPondParameters.pH)]
                } catch let error {
                    print("Error json parsing \(error)")
                }
        }) // databaseHandle
    } // func
} // class

struct FirebaseWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode
    let chartStyle = ChartStyle(backgroundColor: Color("LightDarkModeChartBackground").opacity(0.9), accentColor: Color.theme.background.opacity(0.8), secondGradientColor: Color.theme.background.opacity(0.8), textColor: Color.primary, legendTextColor: Color.primary, dropShadowColor: Color.primary)

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemMedium:
            ZStack {
                LinearGradient(colors: [Color.theme.background.opacity(0.5), Color.theme.background.opacity(0.5/2)], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                HStack {
                    dataSection
                        .padding(.leading, 8.0)
                        .padding([.top, .bottom], 3.0)
                    Spacer()
                    ZStack(alignment: .center) {
                        MultiLineChartView(data: [([70,72,73,71,70,72], GradientColors.blue), ([9.2,10.2,11,10.5,9.8,8.8,8], GradientColors.orange), ([25,40,45,55,35,40,48], GradientColors.green)], style: chartStyle, form: CGSize(width: 190, height: 155))
                        Image("appicon.inapp")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .offset(x: 75, y: -58)
                        .padding(5.0)
                    }
                    .padding(.horizontal, 3.0)
                }
            }
        case .accessoryCircular:
            switch renderingMode {
            case .vibrant:
            if let parameters = entry.pondParameters {
                    ZStack {
                        AccessoryWidgetBackground()
                        Gauge(value: parameters.temperature, in: 60...80, label: {
                            Image("custom.thermometer.sun.fill-1")
                        }, currentValueLabel: {
                            ZStack{
                                Text("\(parameters.temperature ,specifier: "%.0f")\u{00B0}")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }, minimumValueLabel: {
                            Text("\(60)")
                        }, maximumValueLabel: {
                            Text("\(80)")
                        }).gaugeStyle(.accessoryCircular).tint(Color.gray)
                    }.widgetAccentable()
                }
            default:
                if let parameters = entry.pondParameters {
                        ZStack {
                            AccessoryWidgetBackground()
                            Gauge(value: parameters.temperature, label: {
                                Text("\(parameters.temperature ,specifier: "%.0f")")
                            }, currentValueLabel: {
                                ZStack{
                                    Text("\(parameters.temperature ,specifier: "%.0f")").foregroundColor(Color.white)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                            }, minimumValueLabel: {
                                Text("\(60)")
                            }, maximumValueLabel: {
                                Text("\(80)")
                            }).gaugeStyle(.accessoryCircular).tint(Color.gray)
                        }.widgetAccentable()
                    }
            }
        case .accessoryRectangular:
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading) {
                    Text("Pond Health:")
                        .font(.headline)
                        .widgetAccentable()
                    Text("Good!")
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        default :
            ZStack {
                LinearGradient(colors: [Color.theme.background.opacity(0.5), Color.theme.background.opacity(0.5/2)], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                HStack {
                    dataSection
                        .padding(.leading, 8.0)
                        .padding([.top, .bottom], 3.0)
                    Spacer()
                    ZStack(alignment: .center) {
                        MultiLineChartView(data: [([70,72,73,71,70,72], GradientColors.blue), ([9.2,10.2,11,10.5,9.8,8.8,8], GradientColors.orange), ([25,40,45,55,35,40,48], GradientColors.green)], style: chartStyle, form: CGSize(width: 190, height: 155))
                        Image("appicon.inapp")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .offset(x: 75, y: -58)
                        .padding(5.0)
                    }
                    .padding(.horizontal, 3.0)
                }
            }
        }
    }
}

extension FirebaseWidgetEntryView {
    private var dataSection: some View {
        VStack (alignment: .leading, spacing: 1.0){
            if let parameters = entry.pondParameters {
                HStack {
                    ZStack {
                        Circle().padding(2.0).foregroundColor(Color.white)
                        Image("ivfluid.bag")
                            .symbolRenderingMode(.monochrome).foregroundStyle(Color.green).imageScale(.small)
                    }
                    Text("\(parameters.pH, specifier: "%.1f")")
                        .font(.callout).fontWeight(.semibold).foregroundColor(Color.primary)
                }
                HStack {
                    ZStack {
                        Circle().padding(2.0).foregroundColor(Color.white)
                        Image("custom.thermometer.sun.fill-1")
                            .renderingMode(.original).imageScale(.small)
                    }
                    Text("\(parameters.temperature, specifier: "%.1f")\u{00B0}")
                        .font(.callout).fontWeight(.semibold).foregroundColor(Color.primary)
                }
                HStack {
                    ZStack {
                        Circle().padding(2.0).foregroundColor(Color.white)
                        Image("humidity.fill")
                            .symbolRenderingMode(.palette).foregroundStyle(Color.cyan, Color.blue).imageScale(.small)
                    }
                    Text("\(parameters.waterLevel, specifier: "%.1f") in")
                        .font(.callout).fontWeight(.semibold).foregroundColor(Color.primary)
                }
                HStack {
                    ZStack {
                        Circle().padding(2.0).foregroundColor(Color.white)
                        Image("cloud.rain.fill")
                            .symbolRenderingMode(.palette).foregroundStyle(Color.gray.opacity(0.5), Color.blue).imageScale(.small)
                    }
                    Text("\(parameters.turbidityValue) NTU")
                        .font(.callout).fontWeight(.semibold).foregroundColor(Color.primary)
                }
                HStack {
                    ZStack {
                        Circle().padding(2.0).foregroundColor(Color.white)
                        Image("allergens")
                            .symbolRenderingMode(.monochrome).foregroundStyle(Color.orange).imageScale(.small)
                    }
                    Text("\(parameters.totalDissolvedSolids) ppm")
                        .font(.callout).fontWeight(.semibold).foregroundColor(Color.primary)
                }
            } else {
                Text("Fetching Data...").font(.headline).foregroundColor(Color.primary)
            }
        }
    }
}

struct FirebaseWidget: Widget {
    let kind: String = "FirebaseWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            FirebaseWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemMedium,.accessoryCircular,.accessoryInline,.accessoryRectangular])
        .configurationDisplayName("Pond Sensor Data")
        .description("Current Pond Water Quality")
    }
}

struct WaterPHWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode
    
    @ViewBuilder
    var body: some View {
        switch renderingMode {
        case .vibrant:
            if let parameters = entry.pondParameters {
                ZStack {
                    AccessoryWidgetBackground()
                    Gauge(value: parameters.pH, in: 0...14, label: {
                        Text("pH")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }, currentValueLabel: {
//                        ZStack{
//                            Circle().foregroundColor(Color.black)
//                            Text("\(parameters.pH ,specifier: "%.1f")")
//                                .font(.title3)
//                                .fontWeight(.semibold)
//                        }
                        Text("\(parameters.pH ,specifier: "%.1f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }).gaugeStyle(.accessoryCircular)
                }.widgetAccentable()
            }
        default:
            if let parameters = entry.pondParameters {
                ZStack {
                    AccessoryWidgetBackground()
                    Gauge(value: parameters.pH, in: 0...14, label: {
                        Text("pH")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }, currentValueLabel: {
                        Text("\(parameters.pH ,specifier: "%.1f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }).gaugeStyle(.accessoryCircular)
                }.widgetAccentable()
            }
        }
    }
}

struct WaterPHWidget: Widget {
    
    let kind: String = "WaterPHWidget"

    var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WaterPHWidgetEntryView(entry: entry)
            }
        .supportedFamilies([.accessoryCircular,.accessoryInline,.accessoryRectangular])
        .configurationDisplayName("Pond Sensor Data")
        .description("Current Pond Water pH")
    }
}

struct WaterDepthWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    @ViewBuilder
    var body: some View {
        switch renderingMode {
        case .vibrant:
            if let parameters = entry.pondParameters {
                ZStack {
                    AccessoryWidgetBackground()
                    Gauge(value: parameters.waterLevel, in: 6...12, label: {
                        ZStack {
                            Image("humidity.fill")
                                .foregroundColor(Color.white)
                                .font(.body)
                                .fontWeight(.semibold)
                                .offset(x: 2.0, y:-1.0)
                            Image("ruler.fill").rotationEffect(Angle(degrees: -90)).offset(x:-7.0).foregroundColor(Color.black)
                            Image("ruler.fill").rotationEffect(Angle(degrees: 90)).offset(x:-7.0).foregroundColor(Color.white)
                        }
                    }, currentValueLabel: {
                        Text("\(parameters.waterLevel ,specifier: "%.1f")\"")
                            .font(.system(size: 18))
                            .foregroundColor(Color.white)
                            .fontWeight(.semibold)
                    }
                    ).gaugeStyle(.accessoryCircular).tint(Color.gray)
                }.widgetAccentable()
            }
        default:
            if let parameters = entry.pondParameters {
                ZStack {
                    AccessoryWidgetBackground()
                    Gauge(value: parameters.waterLevel, in: 6...12, label: {
                        Image("humidity.fill")
                            .foregroundColor(Color.white)
                            .font(.body)
                            .fontWeight(.semibold)
                    }, currentValueLabel: {
                        ZStack{
                            Circle().foregroundColor(Color.black)
                            Text("\(parameters.waterLevel ,specifier: "%.1f")\"")
                                .font(.system(size: 18))
                                .foregroundColor(Color.white)
                                .fontWeight(.semibold)
                        }
                    }
                    ).gaugeStyle(.accessoryCircular).tint(Color.gray)
                }.widgetAccentable()
            }
        }
    }
}

struct WaterDepthWidget: Widget {

    let kind: String = "WaterDepthWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WaterDepthWidgetEntryView(entry: entry)
            }
        .supportedFamilies([.accessoryCircular,.accessoryInline,.accessoryRectangular])
        .configurationDisplayName("Pond Sensor Data")
        .description("Current Pond Water Depth")
    }
}

struct WaterTurbidityWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    @ViewBuilder
    var body: some View {
        switch renderingMode {
        case .vibrant:
            if let parameters = entry.pondParameters {
                ZStack {
                    AccessoryWidgetBackground()
                    Gauge(value: Double(parameters.turbidityValue), in: 0...3000, label: {
                        Image("cloud.rain.fill")
                    }, currentValueLabel: {
                        Image("cloud.rain.fill")
                    }, minimumValueLabel: {
                        Text("\(0)")//.foregroundColor(Color.white)
                    }, maximumValueLabel: {
                        Text("3K")//.foregroundColor(Color.white)
                    }).gaugeStyle(.accessoryCircular).tint(Color.gray)
                }.widgetAccentable()
            }
        default:
            if let parameters = entry.pondParameters {
                ZStack {
                    AccessoryWidgetBackground()
                    Gauge(value: Double(parameters.turbidityValue), in: 0...3000, label: {
                        Image("cloud.rain.fill")
                    }, currentValueLabel: {
                        ZStack{
                            Circle().foregroundColor(Color.black)
                            Image("cloud.rain.fill")
                        }
                    }, minimumValueLabel: {
                        Text("\(0)").foregroundColor(Color.white)
                    }, maximumValueLabel: {
                        Text("3K").foregroundColor(Color.white)
                    }).gaugeStyle(.accessoryCircular).tint(Color.gray)
                }.widgetAccentable()
            }
        }
    }
}

struct WaterTurbidityWidget: Widget {

    let kind: String = "WaterTurbidityWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WaterTurbidityWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular,.accessoryInline,.accessoryRectangular])
        .configurationDisplayName("Pond Sensor Data")
        .description("Current Pond Water Turbidity")
    }
}

struct WaterTDSWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    @ViewBuilder
    var body: some View {
        switch renderingMode {
        case .vibrant:
            if let parameters = entry.pondParameters {
                ZStack {
                    AccessoryWidgetBackground()
                    Gauge(value: Double(parameters.totalDissolvedSolids), in: 0...1000, label: {
                        Text("TDS")
                            .foregroundColor(Color.white)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }, currentValueLabel: {
                        Text("\(parameters.totalDissolvedSolids)")
                            .foregroundColor(Color.white)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }).gaugeStyle(.accessoryCircular).tint(Color.gray)
                }.widgetAccentable()
            }
        default:
            if let parameters = entry.pondParameters {
                ZStack {
                    AccessoryWidgetBackground()
                    Gauge(value: Double(parameters.totalDissolvedSolids), in: 0...1000, label: {
                        Text("TDS")
                            .foregroundColor(Color.white)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }, currentValueLabel: {
                        ZStack{
                            Circle().foregroundColor(Color.black)
                            Text("\(parameters.totalDissolvedSolids)")
                                .foregroundColor(Color.white)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }).gaugeStyle(.accessoryCircular).tint(Color.gray)
                }.widgetAccentable()
            }
        }
    }
}

struct WaterTDSWidget: Widget {

    let kind: String = "WaterTDSWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WaterTDSWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular,.accessoryInline,.accessoryRectangular])
        .configurationDisplayName("Pond Sensor Data")
        .description("Current Pond Water TDS")
    }
}

@main
struct FirebaseWidgetBundle: WidgetBundle {
    
    init() {
        FirebaseApp.configure()
    }
    
    @WidgetBundleBuilder
    var body: some Widget {
        FirebaseWidget()
        WaterDepthWidget()
        WaterTurbidityWidget()
        WaterTDSWidget()
        WaterPHWidget()
    }
}

struct FirebaseWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FirebaseWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), pondParameters: PondParameters(temperature: 72.3, totalDissolvedSolids: 150, turbidityValue: 3000, turbidityVoltage: 0.5, waterLevel: 12.2, pH: 7.5)))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            WaterPHWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), pondParameters: PondParameters(temperature: 72.3, totalDissolvedSolids: 150, turbidityValue: 3000, turbidityVoltage: 0.5, waterLevel: 12.2, pH: 7.5))).previewContext(WidgetPreviewContext(family: .accessoryCircular))
            FirebaseWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), pondParameters: PondParameters(temperature: 72.3, totalDissolvedSolids: 150, turbidityValue: 3000, turbidityVoltage: 0.5, waterLevel: 12.2, pH: 7.5)))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
//            FirebaseWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
//                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            WaterDepthWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), pondParameters: PondParameters(temperature: 72.3, totalDissolvedSolids: 150, turbidityValue: 3000, turbidityVoltage: 0.5, waterLevel: 12.2, pH: 7.5))).previewContext(WidgetPreviewContext(family: .accessoryCircular))
            WaterTurbidityWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), pondParameters: PondParameters(temperature: 72.3, totalDissolvedSolids: 150, turbidityValue: 3000, turbidityVoltage: 0.5, waterLevel: 12.2, pH: 7.5))).previewContext(WidgetPreviewContext(family: .accessoryCircular))
            WaterTDSWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), pondParameters: PondParameters(temperature: 72.3, totalDissolvedSolids: 150, turbidityValue: 3000, turbidityVoltage: 0.5, waterLevel: 12.2, pH: 7.5))).previewContext(WidgetPreviewContext(family: .accessoryCircular))
        }
    }
}
