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
//        mediaPlayerView.backgroundColor = UIColor(colorScheme == .light ? Color.theme.background : Color.black)
        mediaPlayerView.layer.cornerRadius = 10 // Set the corner radius value as you desire
        mediaPlayerView.layer.masksToBounds = true // Ensures the content is clipped to the corner radius
        
        context.coordinator.mediaPlayer.drawable = mediaPlayerView
        
        // Fetch the latest photo and set it as the background
        context.coordinator.setLatestPhotoBackground(for: mediaPlayerView)

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
        private var hasFetchedBackground = false // Flag to ensure fetch is called only once

        init(_ parent: VLCSwiftUIView) {
            self.parent = parent
            mediaPlayer = VLCSwiftUIView.mediaPlayer
            super.init()
            mediaPlayer.delegate = self            
        }
        
        func setLatestPhotoBackground(for view: UIView) {
            guard !hasFetchedBackground else { return } // Skip if already fetched
            hasFetchedBackground = true // Set the flag to true after the first call

            let urlString = "http://\(Constants.RaspberryPi.IP_ADDRESS):\(Constants.RaspberryPi.CAMERA_SERVICE_PORT)/fetch_photos?count=1"
            guard let url = URL(string: urlString) else { return }

            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error fetching latest photo: \(String(describing: error))")
                    return
                }
                do {
                    let response = try JSONDecoder().decode([String: [Photo]].self, from: data)
                    if let photoUrlString = response["photos"]?.first?.photoUrl,
                       let photoUrl = URL(string: photoUrlString),
                       let imageData = try? Data(contentsOf: photoUrl),
                       let originalImage = UIImage(data: imageData) {

                        // Resize the image to fit the view while maintaining aspect ratio
                        DispatchQueue.main.async {
                            let resizedImage = self.resizeImage(originalImage, toFit: view.bounds.size)
                            view.backgroundColor = UIColor(patternImage: resizedImage)
                        }
                    }
                } catch {
                    print("Error decoding photo response: \(error)")
                }
            }.resume()
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

        func mediaPlayerStateChanged(_ aNotification: Notification) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch self.mediaPlayer.state {
                case .buffering:
                    print("Media player state BUFFERING (\(self.mediaPlayer.state.rawValue))")
                    // Player is buffering, show the latest photo background
//                    if let view = self.mediaPlayer.drawable as? UIView {
//                        self.setLatestPhotoBackground(for: view)
//                    }
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
        
        private func resizeImage(_ image: UIImage, toFit size: CGSize) -> UIImage {
            let aspectWidth = size.width / image.size.width
            let aspectHeight = size.height / image.size.height
            let aspectRatio = min(aspectWidth, aspectHeight)

            let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return resizedImage ?? image // Fallback to original if resizing fails
        }
    }
}

enum IPCamera: String, CaseIterable, Identifiable {
    case cam1 = "Underwater Cam"
//    case cam2 = "Feeding Cam"
    case cam3 = "Pond Cam"

    var id: String { self.rawValue }
    
    var url: String {
        switch self {
        case .cam1: return Secrets.RTSP_URL_CAM1
//        case .cam2: return Secrets.RTSP_URL_CAM2
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

struct Photo: Decodable, Identifiable {
    let id = UUID() // For SwiftUI list
    let photoUrl: String
    let thumbnailUrl: String
    let timestamp: String
}

class PhotoViewModel: ObservableObject {
    @Published var recentPhoto: Photo? = nil
    @Published var photos: [Photo] = []
    @Published var isLoading = false

    private var baseUrl: String {
            return "http://\(Constants.RaspberryPi.IP_ADDRESS):\(Constants.RaspberryPi.CAMERA_SERVICE_PORT)/fetch_photos"
        }
    private let pageSize = 10
    private var lastTimestamp: String? = nil

    init() {
        fetchRecentPhoto()
        fetchPhotos()
    }

    func fetchRecentPhoto() {
        guard let url = URL(string: "\(baseUrl)?count=1") else { return }
        isLoading = true
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            if let error = error {
                print("Error fetching recent photo: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode([String: [Photo]].self, from: data)
                DispatchQueue.main.async {
                    self?.recentPhoto = response["photos"]?.first
                }
//                self?.recentPhoto = response["photos"]?.first
            } catch {
                print("Error decoding recent photo: \(error)")
            }
        }.resume()
    }

    func fetchPhotos() {
        var urlString = "\(baseUrl)?count=\(pageSize)"
        if let timestamp = lastTimestamp {
            urlString += "&before=\(timestamp)"
        }
        guard let url = URL(string: urlString) else { return }

        isLoading = true
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            if let error = error {
                print("Error fetching photos: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode([String: [Photo]].self, from: data)
                if let newPhotos = response["photos"] {
                    DispatchQueue.main.async {
                        self?.photos.append(contentsOf: newPhotos)
                        self?.lastTimestamp = newPhotos.last?.timestamp
                    }
                }
            } catch {
                print("Error decoding photos: \(error)")
            }
        }.resume()
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
    @State private var isTakingPhoto: Bool = false

    @State private var isPhotoViewerPresented: Bool = false // Controls PhotoViewer presentation
    @State private var selectedPhotoIndex: Int? // Index for the selected photo

    let backgroundOpacityValue: Double = 0.5

    @State private var isPlayerPlaying: Bool = false
    @State private var willPlayerPlay: Bool = false
    
    @StateObject private var photoViewModel = PhotoViewModel()
    
    var body: some View {
        VStack (spacing: 0) {
            headerSection
            ZStack {
                LinearGradient(colors: colorScheme == .light ? [Color.theme.background.opacity(backgroundOpacityValue), Color.theme.background.opacity(backgroundOpacityValue/2)] : [Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                VStack {
                    pickerSection
                    cameraPlayerSection
                    cameraButtonSection
                    photoGallerySection
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
        .sheet(isPresented: $isPhotoViewerPresented) {
            if let unwrappedPhotoIndex = selectedPhotoIndex {
                PhotoViewer(
                    photo: $photoViewModel.photos[unwrappedPhotoIndex],
                    selectedPhotoIndex: Binding(
                        get: { unwrappedPhotoIndex },
                        set: { newValue in
                            selectedPhotoIndex = newValue
                        }
                    ),
                    photos: photoViewModel.photos
                )
            }
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
            let screenWidth = geometry.size.width
            let videoAspectRatio: CGFloat = 16.0 / 9.0
            let screenHeight = screenWidth / videoAspectRatio
            
            ZStack {
                VLCSwiftUIView(url: URL(string: selectedCamera.url) ?? URL(fileURLWithPath: ""), isPlayerPlaying: $isPlayerPlaying)
                    .frame(width: screenWidth, height: screenHeight)
                    .scaleEffect(zoomScale)
                    .offset(translation)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                zoomScale = max(1.0, min(value, 2.5))
                                showPlayPauseButton = false
                            }
                            .onEnded { _ in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    zoomScale = 1.0
                                    showPlayPauseButton = true
                                }
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                translation = value.translation
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    translation = .zero
                                }
                            }
                    )

//                if !isPlayerPlaying, let recentPhoto = photoViewModel.recentPhoto, let thumbnailUrl = URL(string: recentPhoto.thumbnailUrl) {
//                    AsyncImage(url: thumbnailUrl) { image in
//                        image.resizable()
//                            .scaledToFit()
//                            .frame(width: screenWidth, height: screenHeight)
//                            .cornerRadius(10)
//                    } placeholder: {
//                        ProgressView()
//                            .tint(Color.theme.background) // Set the tint color to theme accent
//                            .scaleEffect(1.1) // Make the ProgressView larger for better visibility
//                            .frame(width: screenWidth, height: screenHeight)
//                    }
//                }
                
                Image("appicon.inapp")
                    .resizable()
                    .frame(width: 50.0, height: 50.0)
                    .scaledToFit()
                    .rotationEffect(recordRotationAngleValue, anchor: .center)
                    .opacity(fadeDiscOut ? 0 : 1)
                    .opacity(fadeDiscIn ? 1 : 0)
                    .shadow(color: Color.white.opacity(0.5), radius: colorScheme == .light ? 0 : 3, x: -1, y: 1)
                
                // Overlay ProgressView while buffering
                if !isPlayerPlaying {
                    ProgressView()
                        .tint(Color.theme.background) // Set the tint color to theme accent
                        .scaleEffect(1.1) // Make the ProgressView larger for better visibility
                        .frame(width: screenWidth, height: screenHeight)
//                        .background(Color.black.opacity(0.5)) // Optional dimmed background
                }
            }
            
//            VStack {
//                if let url = URL(string: selectedCamera.url) {
//                    let screenWidth = geometry.size.width
//                    let videoAspectRatio: CGFloat = 4.0 / 3.0
//                    let screenHeight = screenWidth / videoAspectRatio
//
//                    ZStack {
//                        VLCSwiftUIView(url: url, isPlayerPlaying: $isPlayerPlaying)
//                            .frame(width: screenWidth, height: screenHeight)
//                            .scaleEffect(zoomScale)
//                            .offset(translation)
//                            .gesture(
//                                MagnificationGesture()
//                                    .onChanged { value in
//                                        let newScale = self.zoomScale * value
//                                        if newScale >= 1.0 && newScale <= 2.5 {
//                                            self.zoomScale = newScale
//                                            self.showPlayPauseButton = false
//                                        }
//                                    }
//                                    .onEnded { _ in
//                                        withAnimation(.easeInOut(duration: 0.25)) {
//                                            self.zoomScale = 1.0
//                                            self.showPlayPauseButton = true
//                                        }
//                                    }
//                                //                                    .onChanged { value in
//                                //                                        withAnimation(.linear(duration: 0.2)) {
//                                //                                            let newScale = self.zoomScale * value
//                                //                                            if newScale >= 1.0 && newScale <= 2.5 {
//                                //                                                self.zoomScale = newScale
//                                //                                                self.showPlayPauseButton = false
//                                //                                            }
//                                //                                        }
//                                //                                    }
//                                //                                    .onEnded { _ in
//                                //                                        withAnimation(.easeInOut(duration: 0.25)) {
//                                //                                            self.zoomScale = 1.0
//                                //                                            self.showPlayPauseButton = true
//                                //                                        }
//                                //                                    }
//                            )
//                            .simultaneousGesture(
//                                DragGesture()
//                                    .onChanged { value in
//                                        withAnimation(.linear(duration: 0.2)) {
//                                            self.translation = value.translation
//                                        }
//                                    }
//                                    .onEnded { value in
//                                        withAnimation(.spring()) {
//                                            self.translation = .zero
//                                        }
//                                    }
//                            )
//                            .gesture(
//                                TapGesture()
//                                    .onEnded { _ in
//                                        withAnimation(.easeInOut(duration: 0.25)) {
//                                            self.zoomScale = 1.0
//                                            self.showPlayPauseButton = true
//                                            self.translation = .zero // Resets the offset translation
//                                        }
//                                    }
//                            )
//                        
//                        Image("appicon.inapp")
//                            .resizable()
//                            .frame(width: 50.0, height: 50.0)
//                            .scaledToFit()
//                            .rotationEffect(recordRotationAngleValue, anchor: .center)
//                            .opacity(fadeDiscOut ? 0 : 1)
//                            .opacity(fadeDiscIn ? 1 : 0)
//                            .shadow(color: Color.white.opacity(0.5), radius: colorScheme == .light ? 0 : 3, x: -1, y: 1)
//                    }
//                } else {
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 10)
//                            .fill(colorScheme == .light ? Color.theme.background : Color.black)
//                            .shadow(color: Color.theme.background.opacity(0.5), radius: 5, x: 0, y: 0)
//                        Text("No stream available")
//                    }.frame(width: 404, height: 303) // this is the size of the video stream for iPhone XR
//                }

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
        }.frame(maxHeight: 250)
//        }.padding(.horizontal, 5)
    }

    private var cameraButtonSection: some View {
        HStack {
            Spacer()
            Button(action: {
                takePhoto()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.theme.accent)
                        .frame(width: 60, height: 60)
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
            }
            .padding()
            .overlay(
                Group {
                    if isTakingPhoto {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Color.theme.accent)
                    }
                }
            )
            Spacer()
        }
    }
    
    private var photoGallerySection: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let videoAspectRatio: CGFloat = 16.0 / 9.0
            let gridItemWidth = (screenWidth - 15) / 2
            let gridItemHeight = gridItemWidth / videoAspectRatio

            ScrollView {
                LazyVGrid(columns: [GridItem(.fixed(gridItemWidth)), GridItem(.fixed(gridItemWidth))], spacing: 5) {
                    ForEach(photoViewModel.photos.indices, id: \.self) { index in
                        let photo = photoViewModel.photos[index]
                        if let thumbnailUrl = URL(string: photo.thumbnailUrl) {
                            AsyncImage(url: thumbnailUrl) { image in
                                image.resizable()
                                    .scaledToFit()
                                    .frame(width: gridItemWidth, height: gridItemHeight)
                                    .cornerRadius(10)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: gridItemWidth, height: gridItemHeight)
                            }
                            .onTapGesture {
                                print("Photo tapped: \(photo.photoUrl)") // Debugging
                                selectedPhotoIndex = index
                                isPhotoViewerPresented = true
                            }
                        }
                    }
                }
                if photoViewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Button("Load More") {
                        photoViewModel.fetchPhotos()
                    }
                    .padding()
                }
            }
        }
    }

    private func takePhoto() {
        guard let url = URL(string: "http://\(Constants.RaspberryPi.IP_ADDRESS):\(Constants.RaspberryPi.CAMERA_SERVICE_PORT)/take_photo") else {
            print("Invalid URL")
            return
        }

        isTakingPhoto = true
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isTakingPhoto = false
            }
            if let error = error {
                print("Error taking photo: \(error)")
                return
            }
            print("Photo taken successfully")
        }.resume()
    }
    
//    private var photoGallerySection: some View {
//        ScrollView {
//            LazyVStack {
//                ForEach(photoViewModel.photos) { photo in
//                    if let thumbnailUrl = URL(string: photo.thumbnailUrl) {
//                        AsyncImage(url: thumbnailUrl) { image in
//                            image.resizable()
//                                .scaledToFit()
//                                .cornerRadius(10)
//                                .padding(.horizontal)
//                        } placeholder: {
//                            ProgressView()
//                                .frame(height: 150)
//                        }
//                        .frame(height: 150)
//                    }
//                }
//                if photoViewModel.isLoading {
//                    ProgressView()
//                        .padding()
//                } else {
//                    Button("Load More") {
//                        photoViewModel.fetchPhotos()
//                    }
//                    .padding()
//                }
//            }
//        }
//    }
}

struct PhotoViewer: View {
    @Binding var photo: Photo // Current photo to display
    @Binding var selectedPhotoIndex: Int // Current index of the photo
    let photos: [Photo] // Array of all photos

    @Environment(\.presentationMode) var presentationMode

    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    private let imageWidth: CGFloat = 3840
    private let imageHeight: CGFloat = 2160

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                HStack {
                    Button(action: showPreviousPhoto) {
                        Image(systemName: "arrow.left")
                            .font(.title)
                            .padding()
                    }
                    .disabled(selectedPhotoIndex == 0) // Disable if on the first photo

                    Spacer()

                    Text(formattedTimestamp(photo.timestamp))
                        .font(.headline)
                        .padding()

                    Spacer()

                    Button(action: showNextPhoto) {
                        Image(systemName: "arrow.right")
                            .font(.title)
                            .padding()
                    }
                    .disabled(selectedPhotoIndex == photos.count - 1) // Disable if on the last photo
                }

                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        if let photoUrl = URL(string: photo.photoUrl) {
                            AsyncImage(url: photoUrl) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: geometry.size.width)
//                                        .scaledToFit()
                                        .scaleEffect(zoomScale)
                                        .offset(offset)
                                        .gesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    zoomScale = max(1.0, min(value, 4.0))
                                                }
                                        )
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    offset = value.translation
                                                }
                                                .onEnded { _ in
                                                    withAnimation(.easeOut) {
                                                        offset = .zero
                                                    }
                                                }
                                        )
                                case .failure:
                                    Text("Unable to load photo")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Text("Unable to load photo")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("Photo Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func formattedTimestamp(_ timestamp: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy h:mm a"
            return displayFormatter.string(from: date)
        }
        return timestamp
    }

    private func showNextPhoto() {
        guard selectedPhotoIndex < photos.count - 1 else { return }
        selectedPhotoIndex += 1
        photo = photos[selectedPhotoIndex]
        resetZoomAndOffset()
    }

    private func showPreviousPhoto() {
        guard selectedPhotoIndex > 0 else { return }
        selectedPhotoIndex -= 1
        photo = photos[selectedPhotoIndex]
        resetZoomAndOffset()
    }

    private func resetZoomAndOffset() {
        zoomScale = 1.0
        offset = .zero
    }
}

struct RTSPStreamView_Previews: PreviewProvider {
    static var previews: some View {
        RTSPStreamView()
            .environmentObject(UserSettings())
    }
}
