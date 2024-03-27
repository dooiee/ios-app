//
//  TESTArduinoColorPicker.swift
//  Project-Shangri-La (iOS)
//
//  Created by Nick Doolittle on 3/21/23.
//

import SwiftUI
import UIKit
import Firebase

struct TESTArduinoColorPicker: View {
    @State private var selectedColor: Color = Color.white
    
    let ref = Database.database().reference()
    
    var body: some View {
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
            }.padding()
        }
    }
}

//MARK: THIS IS BEING USED (Move to extensions)
extension Color {
    var rgbaComponents: (red: Double, green: Double, blue: Double, alpha: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
    
    var hsvComponents: (hue: Double, saturation: Double, value: Double) {
        return rgbToHSV(color: self)
    }

    private func rgbToHSV(color: Color) -> (hue: Double, saturation: Double, value: Double) {
        let components = color.rgbaComponents
        let r = components.red
        let g = components.green
        let b = components.blue
        
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let diff = maxVal - minVal
        
        var hue: Double = 0
        var saturation: Double = 0
        let value = maxVal
        
        if maxVal != 0 {
            saturation = diff / maxVal
        }
        
        if diff != 0 {
            if maxVal == r {
                hue = (g - b) / diff
            } else if maxVal == g {
                hue = 2 + (b - r) / diff
            } else {
                hue = 4 + (r - g) / diff
            }
            hue *= 60
            if hue < 0 {
                hue += 360
            }
        }
        
        return (hue, saturation, value)
    }
}

struct TESTArduinoColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        TESTArduinoColorPicker()
    }
}
