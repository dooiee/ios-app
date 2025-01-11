//
//  NotificationsSettingsView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 1/4/25.
//

import SwiftUI

struct NotificationSettingsView: View {
    @Binding var setting: NotificationSetting
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(setting.parameter)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle(isOn: $setting.isEnabled) {
                    Text(setting.isEnabled ? "On" : "Off")
                        .foregroundColor(.gray)
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            
            if setting.isEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Thresholds")
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Above Threshold")
                                .font(.subheadline)
                            TextField("e.g., 80", value: $setting.aboveThreshold, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Below Threshold")
                                .font(.subheadline)
                            TextField("e.g., 50", value: $setting.belowThreshold, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    HStack {
                        Text("Notification Frequency (seconds)")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    TextField("e.g., 300", value: $setting.notificationFrequency, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    NotificationSettingsView(setting: .constant(NotificationSetting(parameter: "Temperature", aboveThreshold: 80, belowThreshold: 50, notificationFrequency: 300, isEnabled: true)))
}
