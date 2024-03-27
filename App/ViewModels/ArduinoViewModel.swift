//
//  ArduinoViewModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/24/24.
//

import Foundation

class ArduinoViewModel: ObservableObject {
    @Published var ledStatus: LEDStatus?
    @Published var errorMessage: String?
    @Published var nanoStatus: NanoStatus?
    
    func fetchLEDStatus() {
        guard let url = URL(string: "http://\(Constants.Arduino.IP_ADDRESS):\(Constants.Arduino.PORT)/status") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10 // Timeout after 10 seconds
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for basic network errors
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            // Check the response code for HTTP errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                DispatchQueue.main.async {
                    self.errorMessage = "HTTP error: \(httpResponse.statusCode)"
                }
                return
            }
            
            // Attempt to decode the JSON response
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(LEDStatus.self, from: data)
                DispatchQueue.main.async {
                    self.ledStatus = decodedResponse
                    self.errorMessage = nil // Clear any previous error
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func fetchNanoStatus() {
        guard let url = URL(string: "http://\(Constants.Arduino.IP_ADDRESS):\(Constants.Arduino.PORT)/status/nano") else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for basic network errors
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            // Check the response code for HTTP errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                DispatchQueue.main.async {
                    self.errorMessage = "HTTP error: \(httpResponse.statusCode)"
                }
                return
            }
            
            // Attempt to decode the JSON response
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(NanoStatus.self, from: data)
                DispatchQueue.main.async {
                    self.nanoStatus = decodedResponse
                    self.errorMessage = nil // Clear any previous error
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct LEDStatus: Codable {
    var red: Int
    var green: Int
    var blue: Int
    var intensity: Int
}

struct NanoStatus: Codable {
    var connected: Bool
    var peripherals: [Peripheral]
}

struct Peripheral: Codable {
    var name: String
    var status: Bool
    var rssi: Int
}
