import SwiftUI

@main
struct FlightRadarApp: App {
    @StateObject private var aircraftManager = AircraftManager()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(aircraftManager)
                .environmentObject(settings)
        }
    }
}
