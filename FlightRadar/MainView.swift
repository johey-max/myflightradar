
import SwiftUI

struct MainView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var aircraftManager: AircraftManager
    @EnvironmentObject var settings: AppSettings
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // iPhone layout
                ContentView()
            } else {
                // iPad layout
                NavigationSplitView {
                    List {
                        NavigationLink(destination: MapView()) {
                            Label("Map", systemImage: "map")
                        }
                        NavigationLink(destination: AircraftListView()) {
                            Label("List", systemImage: "list.bullet")
                        }
                        NavigationLink(destination: StatisticsView()) {
                            Label("Stats", systemImage: "chart.bar")
                        }
                        NavigationLink(destination: CoverageMapView()) {
                            Label("Coverage", systemImage: "map.circle")
                        }
                    }
                    .navigationTitle("FlightRadar")
                } detail: {
                    // The detail view will be selected from the sidebar
                    MapView()
                }
            }
        }
        .onAppear {
            aircraftManager.startUpdating(serverURL: settings.baseURL)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Resume updates when app becomes active
                aircraftManager.startUpdating(serverURL: settings.baseURL)
            } else if newPhase == .background {
                // Pause updates when app goes to background
                aircraftManager.stopUpdating()
            }
        }
    }
}
