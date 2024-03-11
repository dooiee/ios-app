//
//  RTSPStreamView.swift
//  Project-Shangri-La (iOS)
//
//  Created by Nick Doolittle on 3/18/23.
//

import SwiftUI
import MobileVLCKit

struct VLCSwiftUIView: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    var url: URL
    @Binding var isPlayerPlaying: Bool

    static var mediaPlayer = VLCMediaPlayer()

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let mediaPlayerView = UIView()
        mediaPlayerView.backgroundColor = UIColor(colorScheme == .light ? Color.theme.background : Color.black)
        mediaPlayerView.layer.cornerRadius = 10 // Set the corner radius value as you desire
        mediaPlayerView.layer.masksToBounds = true // Ensures the content is clipped to the corner radius
        context.coordinator.mediaPlayer.drawable = mediaPlayerView

        let pinchRecognizer = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        let panRecognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))

        mediaPlayerView.addGestureRecognizer(pinchRecognizer)
        mediaPlayerView.addGestureRecognizer(panRecognizer)

        return mediaPlayerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let media = VLCMedia(url: url)
        context.coordinator.mediaPlayer.media = media
        context.coordinator.mediaPlayer.play()
        
        if isPlayerPlaying && context.coordinator.mediaPlayer.state != .playing {
            context.coordinator.mediaPlayer.play()
        } else if !isPlayerPlaying && context.coordinator.mediaPlayer.state == .playing {
            context.coordinator.mediaPlayer.pause()
        }
    }

    class Coordinator: NSObject, VLCMediaPlayerDelegate {
        var parent: VLCSwiftUIView
        var mediaPlayer: VLCMediaPlayer
        let maxZoomScale: CGFloat = 3.0

        init(_ parent: VLCSwiftUIView) {
            self.parent = parent
            mediaPlayer = VLCSwiftUIView.mediaPlayer
            super.init()
            mediaPlayer.delegate = self
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            if let view = mediaPlayer.drawable as? UIView {
                let newScale = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale).a
                if newScale >= 1.0 && newScale <= maxZoomScale {
                    view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
                }
                recognizer.scale = 1
            }
        }
        
        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            if let view = mediaPlayer.drawable as? UIView {
                let translation = recognizer.translation(in: view)
                view.transform = view.transform.translatedBy(x: translation.x, y: translation.y)
                recognizer.setTranslation(CGPoint.zero, in: view)
            }
        }

        func mediaPlayerStateChanged(_ aNotification: Notification!) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch self.mediaPlayer.state {
                case .buffering:
                    print("Media player state BUFFERING (\(self.mediaPlayer.state.rawValue))")
                    // Player is buffering, you may want to add additional logic here
                    break
                case .error:
                    // An error occurred, retry playing the stream
                    print("Media player state ERROR (\(self.mediaPlayer.state.rawValue))... Retrying")
                    self.retryPlayingStream()
                    break
                case .playing:
                    // Stream is playing
                    print("Media player state PLAYING (\(self.mediaPlayer.state.rawValue))")
                    self.parent.isPlayerPlaying = true
                    break
                case .stopped:
                    // Stream has stopped, retry playing the stream
                    print("Media player state STOPPED (\(self.mediaPlayer.state.rawValue))")
                    self.retryPlayingStream()
                    break
                case .paused:
                    // Stream is paused
                    print("Media player state PAUSED (\(self.mediaPlayer.state.rawValue))")
                default:
                    break
                }
            }
        }

        func retryPlayingStream() {
            // Retry playing the stream after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.mediaPlayer.play()
            }
        }
    }
}

enum IPCamera: String, CaseIterable, Identifiable {
    case cam1 = "Underwater Cam"
    case cam2 = "Feeding Cam"
    case cam3 = "Pond Cam"

    var id: String { self.rawValue }
    
    var url: String {
        switch self {
        case .cam1: return Secrets.RTSP_URL_CAM1
        case .cam2: return Secrets.RTSP_URL_CAM2
        case .cam3: return Secrets.RTSP_URL_CAM3
        }
    }
}

struct AnimatingCircle: View {
    @Binding var isAnimating: Bool

    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 6, height: 6)
            .scaleEffect(isAnimating ? 1.5 : 1)
            .opacity(isAnimating ? 0 : 1)
            .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
    }
}


struct RTSPStreamView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var userSettings: UserSettings //testing
    @State private var selectedCamera: IPCamera = .cam1 //testing

    @State private var zoomScale: CGFloat = 1.0
    @State private var translation: CGSize = .zero
    @State private var isPlaying: Bool = true
    @State var fadeDiscOut: Bool = false
    @State var fadeDiscIn: Bool = false
    @State var recordRotationAngleValue: Angle = Angle(degrees: 0)
    @State var showPlayPauseButton: Bool = true

    @State private var showCameraSettingsPage: Bool = false // Flag to control showing of camera settings view

    let backgroundOpacityValue: Double = 0.5

    @State private var isPlayerPlaying: Bool = false
    @State private var willPlayerPlay: Bool = false
    
    var body: some View {
        VStack (spacing: 0) {
            headerSection
            ZStack {
                LinearGradient(colors: colorScheme == .light ? [Color.theme.background.opacity(backgroundOpacityValue), Color.theme.background.opacity(backgroundOpacityValue/2)] : [Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                VStack {
                    pickerSection
                    cameraPlayerSection
                }
            }
        }
        .onAppear {
            self.selectedCamera = userSettings.defaultCamera
        }
        .onDisappear {
            VLCSwiftUIView.mediaPlayer.stop()
        }
        .fullScreenCover(isPresented: $showCameraSettingsPage) {
            CameraSettingsView(showCameraSettingsPage: $showCameraSettingsPage)
                .environmentObject(userSettings)
        }
    }
}

extension RTSPStreamView {    
    private var headerSection: some View {
        ZStack (alignment: .top) { 
            LinearGradient(colors: colorScheme == .light ? [Color.theme.background.opacity(0.8), Color.theme.background.opacity(backgroundOpacityValue)] : [Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
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
                ZStack {
                    Text("FishyCam").font(.title2).bold()
                    if isPlayerPlaying {
                        AnimatingCircle(isAnimating: $isPlayerPlaying)
                            .offset(x: 60)
                    }
                }
                // Text("FishyCam").font(.title2).bold()
                Spacer()
                Button(action: { 
                    withAnimation(.spring()) { 
                        self.showCameraSettingsPage = true 
                    } 
                }) {
                    ZStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.clear)
                            .font(.title)
                            .padding()
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(colorScheme == .light ? Color.black : Color.secondary)
                            .scaleEffect(1.3)
                            .padding()
                    }    
                }
            }
        }.frame(height: 60)
    }
    private var pickerSection: some View {
        Picker("Camera", selection: $selectedCamera) {
            ForEach(IPCamera.allCases) { camera in
                Text(camera.rawValue).tag(camera)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding([.horizontal, .top], 10)
    }

    private var cameraPlayerSection: some View {
        GeometryReader { geometry in
            VStack {
                if let url = URL(string: selectedCamera.url) {
                    let screenWidth = geometry.size.width
                    let videoAspectRatio: CGFloat = 4.0 / 3.0
                    let screenHeight = screenWidth / videoAspectRatio

                    ZStack {
                        VLCSwiftUIView(url: url, isPlayerPlaying: $isPlayerPlaying)
                            .frame(width: screenWidth, height: screenHeight)
                            .scaleEffect(zoomScale)
                            .offset(translation)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let newScale = self.zoomScale * value
                                        if newScale >= 1.0 && newScale <= 2.5 {
                                            self.zoomScale = newScale
                                            self.showPlayPauseButton = false
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.zoomScale = 1.0
                                            self.showPlayPauseButton = true
                                        }
                                    }
                                //                                    .onChanged { value in
                                //                                        withAnimation(.linear(duration: 0.2)) {
                                //                                            let newScale = self.zoomScale * value
                                //                                            if newScale >= 1.0 && newScale <= 2.5 {
                                //                                                self.zoomScale = newScale
                                //                                                self.showPlayPauseButton = false
                                //                                            }
                                //                                        }
                                //                                    }
                                //                                    .onEnded { _ in
                                //                                        withAnimation(.easeInOut(duration: 0.25)) {
                                //                                            self.zoomScale = 1.0
                                //                                            self.showPlayPauseButton = true
                                //                                        }
                                //                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        withAnimation(.linear(duration: 0.2)) {
                                            self.translation = value.translation
                                        }
                                    }
                                    .onEnded { value in
                                        withAnimation(.spring()) {
                                            self.translation = .zero
                                        }
                                    }
                            )
                            .gesture(
                                TapGesture()
                                    .onEnded { _ in
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.zoomScale = 1.0
                                            self.showPlayPauseButton = true
                                            self.translation = .zero // Resets the offset translation
                                        }
                                    }
                            )
                        
                        Image("appicon.inapp")
                            .resizable()
                            .frame(width: 50.0, height: 50.0)
                            .scaledToFit()
                            .rotationEffect(recordRotationAngleValue, anchor: .center)
                            .opacity(fadeDiscOut ? 0 : 1)
                            .opacity(fadeDiscIn ? 1 : 0)
                            .shadow(color: Color.white.opacity(0.5), radius: colorScheme == .light ? 0 : 3, x: -1, y: 1)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .light ? Color.theme.background : Color.black)
                            .shadow(color: Color.theme.background.opacity(0.5), radius: 5, x: 0, y: 0)
                        Text("No stream available")
                    }.frame(width: 404, height: 303) // this is the size of the video stream for iPhone XR
                }

                Button(action: {
                    self.isPlaying.toggle()
                    if self.isPlaying {
                        VLCSwiftUIView.mediaPlayer.play()
                        withAnimation(.easeInOut(duration: 2.0)) {
                            recordRotationAngleValue = Angle(degrees: 2880)
                            fadeDiscOut = true
                            fadeDiscIn = false
                        }
                    } else {
                        VLCSwiftUIView.mediaPlayer.pause()
                        withAnimation(.easeInOut(duration: 2.0)) {
                            recordRotationAngleValue = Angle(degrees: 2880)
                            fadeDiscIn = true
                            fadeDiscOut = false
                        }
                    }
                    recordRotationAngleValue = Angle(degrees: 0)
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.theme.accent)
                        .clipShape(Circle())
                }
                .opacity(showPlayPauseButton ? 1.0 : 0.0)
                
//                Text("isPlayerPlaying: \(VLCSwiftUIView.mediaPlayer.state.rawValue)")
            }
        }.padding(.horizontal, 5)
    }
}

struct RTSPStreamView_Previews: PreviewProvider {
    static var previews: some View {
        RTSPStreamView()
            .environmentObject(UserSettings())
    }
}
