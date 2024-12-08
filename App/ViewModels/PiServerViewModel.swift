//
//  PiServerViewModel.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 12/07/24.
//

import Foundation

class PiServerViewModel: ObservableObject {
    @Published var serverStatus: ServerStatus?
    @Published var serverStatusError: String?
    @Published var peripheralStatus: PeripheralStatus?
    @Published var peripheralStatusError: String?
    
    func resetStatuses() {
        DispatchQueue.main.async {
            self.serverStatus = nil
            self.peripheralStatus = nil
            self.serverStatusError = nil
            self.peripheralStatusError = nil
        }
    }
    
    func fetchStatus() {
        Task {
            await fetchStatusAsync()
        }
    }
    
    private func fetchStatusAsync() async {
        guard let url = URL(string: "http://\(Constants.RaspberryPi.IP_ADDRESS):\(Constants.RaspberryPi.PORT)/status") else {
            DispatchQueue.main.async {
                self.serverStatusError = "Invalid URL"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5 // Timeout after 10 seconds
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.serverStatusError = "HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)"
                }
                return
            }

            DispatchQueue.main.async {
                do {
                    self.serverStatus = try JSONDecoder().decode(ServerStatus.self, from: data)
                    self.serverStatusError = nil
                    print("Server Status: \(String(describing: self.serverStatus))")

                    // Safely unwrap serverStatus
                    if let unwrappedServerStatus = self.serverStatus {
                        // Populate PeripheralStatus based on peripheralConnected boolean
                        self.peripheralStatus = PeripheralStatus(
                            connected: unwrappedServerStatus.peripheralConnected,
                            signalStrength: unwrappedServerStatus.peripheralRSSI, // Use peripheralRSSI
                            timeSinceLastConnection: unwrappedServerStatus.peripheralConnected ? nil : unwrappedServerStatus.timestamp
                        )
                        self.peripheralStatusError = nil
                    } else {
                        self.peripheralStatusError = "Server status is nil"
                    }
                } catch {
                    self.serverStatusError = "Decoding error: \(error.localizedDescription)"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.serverStatusError = "Network error: \(error.localizedDescription)"
            }
        }
    }
}

struct ServerStatus: Codable {
    var status: String
    var peripheralConnected: Bool
    var peripheralRSSI: Int? // New field for signal strength
    var timestamp: String
}

struct PeripheralStatus: Codable {
    var connected: Bool
    var signalStrength: Int?
    var timeSinceLastConnection: String?

    enum CodingKeys: String, CodingKey {
        case connected
        case signalStrength = "rssi"
        case timeSinceLastConnection
    }
}
