//
//  Color.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/6/22.
//

import Foundation
import SwiftUI

extension Color {
    
    static let theme = ColorTheme()
    static let launch = LaunchTheme()
    
}

struct ColorTheme {

    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
    let primaryText = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    let secondaryText = #colorLiteral(red: 1, green: 0.4980392157, blue: 0.4980392157, alpha: 1)
    let tertiaryText = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
    let gray = #colorLiteral(red: 0.6642242074, green: 0.6642400622, blue: 0.6642315388, alpha: 1)
    let batteryGreen = Color(red: 14/255, green: 252/255, blue: 5/255)
    let batteryYellow = Color(red: 254/255, green: 207/255, blue: 15/255)
    let accentBabyBlue = Color("AccentColorBabyBlue")
    let accentGreen = Color("AccentColorGreen")
    let accentPeach = Color("AccentColorPeach")
    let accentLavender = Color("AccentColorLavender")
    let accentNightModeGray = Color("AccentColorNightModeGray")
}

struct LaunchTheme {
    
    //let accent = Color("LaunchAccentColor")
    let background = Color("LaunchScreenBackground")
    
}
