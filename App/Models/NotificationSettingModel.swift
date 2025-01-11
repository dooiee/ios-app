//
//  NotificationSettingsSheet.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 1/4/25.
//

import Foundation

struct NotificationSetting: Identifiable, Equatable {
    let id = UUID()
    var parameter: String
    var aboveThreshold: Double?
    var belowThreshold: Double?
    var notificationFrequency: Int // in seconds
    var isEnabled: Bool
    
    static func == (lhs: NotificationSetting, rhs: NotificationSetting) -> Bool {
        lhs.parameter == rhs.parameter &&
        lhs.aboveThreshold == rhs.aboveThreshold &&
        lhs.belowThreshold == rhs.belowThreshold &&
        lhs.notificationFrequency == rhs.notificationFrequency &&
        lhs.isEnabled == rhs.isEnabled
    }
}
