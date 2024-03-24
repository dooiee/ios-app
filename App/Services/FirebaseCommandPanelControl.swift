//
//  FirebaseCommandPanelControl.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/28/23.
//

import Foundation
import Firebase
import Combine
import CodableFirebase
import SwiftUI

extension DatabaseReference {
    func observeSingleEventPublisher() -> Future<DataSnapshot, Error> {
        return Future<DataSnapshot, Error> { [weak self] promise in
            self?.observeSingleEvent(of: .value, with: { snapshot in
                promise(.success(snapshot))
            }, withCancel: { error in
                promise(.failure(error))
            })
        }
    }
}

struct ControlPanelConfig {
    let parentPath: String
//    let wifiStatusPath: String
//    let wifiRssiPath: String
    let onBoardLEDColorRGBRedPath: String
    let onBoardLEDColorRGBGreenPath: String
    let onBoardLEDColorRGBBluePath: String
    let onBoardLEDColorBrightnessPath: String
    let onBoardLEDColorLastUpdatedPath: String
}

class ArduinoControlViaFirebase<ValueType: Codable>: ObservableObject {

    @Published var value: ValueType?
    @Published var error: Error?

    private let config: ControlPanelConfig
    private let ref: DatabaseReference
    private var cancellable: AnyCancellable?

    init(config: ControlPanelConfig) {
        self.config = config
        self.ref = Database.database().reference().child(config.parentPath)
    }

    func getValue() {
        cancellable = ref
            .observeSingleEventPublisher()
            .tryMap { snapshot -> ValueType in
                guard let value = snapshot.value else {
                    throw FirebaseError.noValue
                }
                return try FirebaseDecoder().decode(ValueType.self, from: value)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                }
            }, receiveValue: { [weak self] value in
                self?.value = value
            })
    }

    func setValue(_ value: ValueType) {
        do {
            let data = try FirebaseEncoder().encode(value)
            ref.setValue(data)
        } catch {
            self.error = error
        }
    }

    func cancel() {
        cancellable?.cancel()
    }
    
    func setOnBoardLEDColor(color: Color, completion: @escaping (Bool) -> Void) {
        let components = color.rgbaComponents
        let values = [
            config.onBoardLEDColorRGBRedPath: Int(components.red * 255),
            config.onBoardLEDColorRGBGreenPath: Int(components.green * 255),
            config.onBoardLEDColorRGBBluePath: Int(components.blue * 255),
            config.onBoardLEDColorBrightnessPath: Int(components.alpha * 100),
            config.onBoardLEDColorLastUpdatedPath: ServerValue.timestamp()
        ] as [String : Any]
        
        ref.updateChildValues(values) { (error, _) in
            completion(error == nil)
        }
    }
    
    //TODO: function to update board reset count and log timestamp
//    func pushResetCountAndLog(board: Board, completion: @escaping (Bool) -> Void) {
////        let components = color.rgbaComponents
//        let updates = [
////            config.
//          "posts/\(postID)/stars/\(userID)": true,
//          "posts/\(postID)/starCount": ServerValue.increment(1),
//          "user-posts/\(postID)/stars/\(userID)": true,
//          "user-posts/\(postID)/starCount": ServerValue.increment(1)
//        ] as [String : Any]
//
//        ref.updateChildValues(updates) { (error, _) in
//            completion(error == nil)
//        }
//    }
    
//    private func uploadWifiStatus() {
//        ref.child(config.wifiStatusPath).setValue(ServerValue.timestamp())
//    }
//
//    private func uploadWifiRSSI() {
//        ref.child(config.wifiRssiPath).setValue(ServerValue.timestamp())
//    }
}

enum FirebaseError: Error {
    case noValue
}

struct LEDColorData: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var brightness: Double
    var lastUpdated: Double
}
