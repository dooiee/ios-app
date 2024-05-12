//
//  ArduinoViewModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/24/24.
//

import Foundation

class ArduinoViewModel: ObservableObject {
    @Published var ledStatus: LEDStatus?
    @Published var ledStatusError: String?
    @Published var nanoStatus: NanoStatus?
    @Published var nanoStatusError: String?
    
    func resetStatuses() {
        DispatchQueue.main.async {
            self.ledStatus = nil
            self.nanoStatus = nil
            self.ledStatusError = nil
            self.nanoStatusError = nil
        }
    }
    
    // New function that wraps the fetching process
    func fetchStatusesSequentially() async {
        await fetchLEDStatusAsync()
//        await fetchNanoStatus()
    }
    
    func fetchLEDStatus() {
        Task {
            await fetchLEDStatusAsync()
        }
    }
    
    private func fetchLEDStatusAsync() async {
        guard let url = URL(string: "http://\(Constants.Arduino.IP_ADDRESS):\(Constants.Arduino.PORT)/status") else {
            DispatchQueue.main.async {
                self.ledStatusError = "Invalid URL"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5 // Timeout after 10 seconds
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.ledStatusError = "HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)"
                }
                return
            }

            DispatchQueue.main.async {
                do {
                    self.ledStatus = try JSONDecoder().decode(LEDStatus.self, from: data)
                    self.ledStatusError = nil
                    print("LED Status: \(String(describing: self.ledStatus))")
                } catch {
                    self.ledStatusError = "Decoding error: \(error.localizedDescription)"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.ledStatusError = "Network error: \(error.localizedDescription)"
            }
        }
    }

    private func fetchNanoStatus() async {
        guard let url = URL(string: "http://\(Constants.Arduino.IP_ADDRESS):\(Constants.Arduino.PORT)/status/nano") else {
            DispatchQueue.main.async {
                self.nanoStatusError = "Invalid URL"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5 // Timeout after 10 seconds
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.nanoStatusError = "HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)"
                }
                return
            }

            DispatchQueue.main.async {
                do {
                    self.nanoStatus = try JSONDecoder().decode(NanoStatus.self, from: data)
                    self.nanoStatusError = nil
                } catch {
                    self.nanoStatusError = "Decoding error: \(error.localizedDescription)"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.nanoStatusError = "Network error: \(error.localizedDescription)"
            }
        }
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
    var signalStrength: Int?
    var timeSinceLastConnection: Int? // Time in seconds

    enum CodingKeys: String, CodingKey {
        case connected
        case signalStrength = "rssi"
        case timeSinceLastConnection
    }
}
