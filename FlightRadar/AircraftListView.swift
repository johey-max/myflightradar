import SwiftUI

struct AircraftListView: View {
    @EnvironmentObject var aircraftManager: AircraftManager
    @State private var searchText = ""

    var filteredAircraft: [Aircraft] {
        if searchText.isEmpty {
            return aircraftManager.aircraft
        } else {
            return aircraftManager.aircraft.filter { aircraft in
                aircraft.callsign.localizedCaseInsensitiveContains(searchText) ||
                aircraft.hex.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            ForEach(filteredAircraft) { aircraft in
                NavigationLink(destination: AircraftDetailView(aircraft: aircraft)) {
                    AircraftRow(aircraft: aircraft)
                }
            }
        }
        .navigationTitle("Aircraft")
        .searchable(text: $searchText, prompt: "Search by callsign or ICAO")
        .overlay {
            if filteredAircraft.isEmpty {
                ContentUnavailableView(
                    "No Aircraft",
                    systemImage: "airplane.departure",
                    description: Text(searchText.isEmpty ? "Waiting for aircraft data..." : "No aircraft match your search")
                )
            }
        }
    }
}

struct AircraftRow: View {
    let aircraft: Aircraft

    var body: some View {
        HStack {
            Image(systemName: "airplane")
                .font(.title2)
                .foregroundColor(altitudeColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(aircraft.callsign)
                    .font(.headline)

                Text(aircraft.hex.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(aircraft.altitude) ft")
                    .font(.subheadline)

                Text("\(Int(aircraft.groundSpeed)) kts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var altitudeColor: Color {
        let altitude = aircraft.altitude
        if altitude < 5000 {
            return .green
        } else if altitude < 20000 {
            return .yellow
        } else {
            return .blue
        }
    }
}
