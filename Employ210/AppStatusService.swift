//
//  AppStatusService.swift
//  Employ210
//
//  Fetches the remote maintenance flag on cold launch and every foreground re-entry.
//  FAIL OPEN: any network error or timeout defaults to isInMaintenance = false (normal app).
//
//  Remote JSON shape:
//    { "maintenanceMode": true, "message": "Back in 30 minutes." }
//
//  Set AWSConfig.statusURL to your status endpoint before shipping.
//

import Foundation

private struct AppStatus: Decodable {
    let maintenanceMode: Bool
    let message: String
}

@MainActor
final class AppStatusService: ObservableObject {
    @Published private(set) var isInMaintenance = false
    @Published private(set) var maintenanceMessage = ""

    func check() {
        Task { await fetchStatus() }
    }

    private func fetchStatus() async {
        // Fail open immediately if no URL is configured
        guard !AWSConfig.statusURL.isEmpty,
              let url = URL(string: AWSConfig.statusURL) else { return }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3
        config.timeoutIntervalForResource = 3
        let session = URLSession(configuration: config)

        do {
            let (data, _) = try await session.data(from: url)
            let status = try JSONDecoder().decode(AppStatus.self, from: data)
            isInMaintenance = status.maintenanceMode
            maintenanceMessage = status.message
        } catch {
            // Fail open — network error, timeout, or bad JSON → show normal app
            isInMaintenance = false
        }
    }
}
