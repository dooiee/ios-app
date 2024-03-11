//
//  CameraSettingsView.swift
//  Project-Shangri-La (iOS)
//
//  Created by Nick Doolittle on 5/16/23.
//

import SwiftUI

struct CameraSettingsView: View {
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var userSettings: UserSettings
    @Binding var showCameraSettingsPage: Bool

    var body: some View {
        ZStack {
            colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
            VStack {
                headerSection
                List {
                    defaultCameraSetting
                }
                Spacer()
            }
            .background(colorScheme == .light ? Color(red: 0.949, green: 0.949, blue: 0.97) : Color.black)
        }
    }
}

extension CameraSettingsView {
    private var headerSection: some View {
        HStack {
            Button {
                showCameraSettingsPage = false
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(colorScheme == .light ? Color.black : Color.secondary)
                    .font(.title)
                    .padding()
            }
            Spacer()
            Text("FishyCam Settings").font(.title2).bold()
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

    private var defaultCameraSetting: some View {
        Section(header: Text("Camera Settings")) {
            HStack {
                Image(systemName: "video.circle.fill").foregroundColor(.blue)
                    .imageScale(.large)
                Spacer()
                Picker(selection: $userSettings.defaultCamera) {
                    ForEach(IPCamera.allCases) { camera in
                        Text(camera.rawValue).tag(camera)
                    }
                } label: {
                    Text("Default Cam")
                }.pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct CameraSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CameraSettingsView(showCameraSettingsPage: .constant(true)).environmentObject(UserSettings())
    }
}
