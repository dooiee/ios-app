//
//  FirebaseListRowViewTest.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/11/22.
//

import SwiftUI

struct FirebaseListRowViewIcon: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State var parameterIcon: String
    @State var customIcon: Bool = false
    
    let chartIcon = "chart.xyaxis.line"
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 60, height: 55, alignment: .topLeading)
                .foregroundColor(colorScheme == .light ? Color(hue: 0.088, saturation: 0.0, brightness: 1.0, opacity: 0.974) : Color.theme.accentNightModeGray)
                .shadow(
                    color: Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.105),
                  radius: 1,
                    x: colorScheme == .light ? -2 : -1,
                    y: colorScheme == .light ? -2 : -1)
                .shadow(
                    color: Color(hue: 1.0, saturation: 0.012, brightness: 0.851, opacity: 0.594),
                  radius: 2,
                    x: colorScheme == .light ? 4 : 3,
                    y: colorScheme == .light ? 4 : 3)
            
            Image(systemName: chartIcon)
                .opacity(0.2)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 35).weight(.regular))
                .offset(x: 8, y: -8)
            
            if customIcon {
                if colorScheme == .light {
                    Image(parameterIcon)
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(Color.white)
                        .font(.system(size: 30).weight(.regular))
                        .imageScale(.medium)
                        .offset(x: -13, y: 4)
                        .shadow(color: Color.gray.opacity(0.5), radius: 2, x: 2, y: 3)
                }
                Image(parameterIcon)
                    .renderingMode(.original)
                    .font(.system(size: 30).weight(.regular))
                    .imageScale(.medium)
                    .offset(x: -13, y: 4)
                    .shadow(color: colorScheme == .light ? Color.white : Color.gray.opacity(0.5), radius: colorScheme == .light ? 1 : 2, x: 2, y: 3)
            }
            else if parameterIcon == "humidity.fill" {
                Image(systemName: parameterIcon)
                    .symbolRenderingMode(.palette)
                    .font(.system(size: 30).weight(.regular))
                    .imageScale(.medium)
                    .foregroundStyle(.blue, .cyan)
                    .offset(x: -10, y: 6)
                    .shadow(color: Color.gray.opacity(0.6), radius: 2, x: 2, y: 1)
            }
            else if parameterIcon == "cloud.rain.fill" {
                Image(systemName: parameterIcon)
                    .symbolRenderingMode(.palette)
                    .font(.system(size: 30).weight(.regular))
                    .imageScale(.medium)
                    .foregroundStyle(colorScheme == .light ? Color(hue: 1.0, saturation: 0.044, brightness: 0.873) : Color.white, .cyan)
                    .offset(x: -10, y: 6)
                    .shadow(color: Color.gray.opacity(0.6), radius: 2, x: 2, y: 1)
            }
            else if parameterIcon == "allergens" {
                Image(systemName: "allergens")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 25).weight(.regular))
                    .rotationEffect(Angle(degrees: -90))
                    .imageScale(.medium)
                    .foregroundStyle(Color.orange)
                    .offset(x: -10, y: 6)
                    .shadow(color: Color.gray.opacity(0.6), radius: 2, x: 2, y: 2)
            }
            else if parameterIcon == "ivfluid.bag" {
                Image(systemName: "ivfluid.bag")
                    .font(.system(size: 30).weight(.regular))
                    .foregroundColor(Color.mint.opacity(0.7))
                    .imageScale(.medium)
                    .offset(x: -11, y: 5)
                    .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 2, y: 2)
            }
            else {
                Image(systemName: parameterIcon)
                    .font(.system(size: 30).weight(.regular))
                    .imageScale(.medium)
                    .offset(x: -10, y: 6)
                    .shadow(color: Color.gray.opacity(0.6), radius: 2, x: 2, y: 2)
            }
        }
    }
}

struct FirebaseListRowViewTitle: View {
    
    @State var parameterTitle: String
    @State var parameterSubtitle: String? = nil
    @State var parameterSubtitleDouble: Double? = nil
    @State var parameterSubtitleDoubleSpecifier: String? = nil
    @State var parameterSubtitleDoubleUnits: String? = nil
    
    var body: some View {
        VStack (alignment: .leading) {
            Text(parameterTitle)
                .foregroundColor(Color.primary)
                .font(.headline)
                .bold()
                .fixedSize()
            if let parameterSubtitle = parameterSubtitle {
                Text(parameterSubtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .bold()
            }
            if let parameterSubtitleDouble = parameterSubtitleDouble {
                Text("\(parameterSubtitleDouble, specifier: parameterSubtitleDoubleSpecifier ?? "%.2f")\(parameterSubtitleDoubleUnits ?? "")")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .bold()
            }
        }
    }
}

struct FirebaseListRowViewIcon_Previews: PreviewProvider {
    static var previews: some View {
        FirebaseListRowViewIcon(parameterIcon: "custom.thermometer.sun.fill-1", customIcon: true)
    }
}
