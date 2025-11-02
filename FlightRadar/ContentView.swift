import SwiftUI

struct ContentView: View {
    @EnvironmentObject var aircraftManager: AircraftManager
    @EnvironmentObject var settings: AppSettings
    @State private var showSettings = false

    var body: some View {
        TabView {
            NavigationView {
                MapView()
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }

            AircraftListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }

            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            CoverageMapView()
                .tabItem {
                    Label("Coverage", systemImage: "map.circle")
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
