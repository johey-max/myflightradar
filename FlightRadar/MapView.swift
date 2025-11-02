import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var aircraftManager: AircraftManager
    @EnvironmentObject var settings: AppSettings
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.284043, longitude: -124.792703),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
    )
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Map(position: $position) {
                // Draw aircraft trails
                if aircraftManager.showTrails {
                    ForEach(Array(aircraftManager.trails.keys), id: \.self) { hex in
                        if let trail = aircraftManager.trails[hex], trail.points.count > 1 {
                            MapPolyline(coordinates: trail.points.map { $0.coordinate })
                                .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                        }
                    }
                }

                // Draw aircraft markers
                ForEach(aircraftManager.aircraft) { aircraft in
                    if let coordinate = aircraft.coordinate {
                        Annotation(aircraft.callsign, coordinate: coordinate) {
                            AircraftAnnotation(
                                aircraft: aircraft,
                                origin: aircraftManager.flightInfo[aircraft.hex]?.origin
                            )
                            .onTapGesture {
                                aircraftManager.selectAircraft(aircraft, openSkyClientId: settings.openSkyClientId, openSkyClientSecret: settings.openSkyClientSecret)
                            }
                            .task(id: aircraft.hex) {
                                // Fetch flight info when aircraft appears on map (debounced)
                                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                                if aircraftManager.flightInfo[aircraft.hex] == nil {
                                    await aircraftManager.fetchFlightInfo(for: aircraft, clientId: settings.openSkyClientId, clientSecret: settings.openSkyClientSecret)
                                }
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(aircraftManager.aircraft.count) Aircraft")
                            .font(.headline)
                        if let lastUpdate = aircraftManager.lastUpdate {
                            Text("Updated \(timeAgo(lastUpdate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)

                    Spacer()

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.title3)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                if let selected = aircraftManager.selectedAircraft {
                    AircraftDetailCard(aircraft: selected)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            return "\(seconds / 60)m ago"
        }
    }
}

struct AircraftAnnotation: View {
    let aircraft: Aircraft
    let origin: String?

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 3)

                Image(systemName: "airplane")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(aircraft.heading - 90))
                    .foregroundColor(altitudeColor)
            }

            VStack(spacing: 0) {
                Text(aircraft.callsign)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)

                let aircraftType = aircraft.aircraftType
                if aircraftType != "Unknown" {
                    Text(aircraftType)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.yellow)
                }

                if let origin = origin {
                    let airportName = AirportDirectory.name(for: origin)
                    if airportName != origin.uppercased() {
                        Text(airportName)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    } else {
                        Text(origin.uppercased())
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: 100)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.85))
            )
        }
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

struct AircraftDetailCard: View {
    @EnvironmentObject var aircraftManager: AircraftManager
    let aircraft: Aircraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(aircraft.callsign)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(aircraft.hex.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    aircraftManager.selectedAircraft = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Altitude", systemImage: "arrow.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(aircraft.altitude) ft")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label("Speed", systemImage: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(aircraft.groundSpeed)) kts")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label("Heading", systemImage: "location.north.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(aircraft.heading))°")
                        .font(.headline)
                }
            }

            if let squawk = aircraft.squawk {
                HStack {
                    Label("Squawk", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(squawk)
                        .font(.headline)
                }
            }

            // Enhanced flight info from OpenSky
            if let flightInfo = aircraftManager.flightInfo[aircraft.hex] {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Flight Information")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Show route information
                    if let origin = flightInfo.origin {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("From:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(origin.uppercased())
                                    .font(.headline)
                            }
                            Text(AirportDirectory.name(for: origin))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            if let destination = flightInfo.destination {
                                HStack {
                                    Text("To:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(destination.uppercased())
                                        .font(.headline)
                                }
                                Text(AirportDirectory.name(for: destination))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                Text("Destination: In Flight")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .italic()
                            }
                        }
                    }

                    if let departure = flightInfo.departure {
                        HStack {
                            Text("Departed:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(departure, style: .relative)
                                .font(.caption)
                        }
                    }
                }
            }

            NavigationLink(destination: AircraftDetailView(aircraft: aircraft)) {
                Text("View Full Details")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}
