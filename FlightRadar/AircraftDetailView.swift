import SwiftUI
import MapKit

struct AircraftDetailView: View {
    @EnvironmentObject var aircraftManager: AircraftManager
    @EnvironmentObject var settings: AppSettings
    let aircraft: Aircraft

    @State private var position: MapCameraPosition

    init(aircraft: Aircraft) {
        self.aircraft = aircraft

        if let coord = aircraft.coordinate {
            _position = State(initialValue: .region(
                MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            ))
        } else {
            _position = State(initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                )
            ))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map showing aircraft location
                if let coordinate = aircraft.coordinate {
                    Map(position: $position) {
                        Annotation(aircraft.callsign, coordinate: coordinate) {
                            Image(systemName: "airplane")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .rotationEffect(.degrees(aircraft.heading))
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                }

                // Aircraft Photo
                if let photo = aircraftManager.aircraftPhotos[aircraft.hex],
                   let photoUrlString = photo.photoUrl,
                   let photoUrl = URL(string: photoUrlString) {
                    VStack(alignment: .leading, spacing: 8) {
                        AsyncImage(url: photoUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                EmptyView()
                            @unknown default:
                                EmptyView()
                            }
                        }

                        if let photographer = photo.photographer {
                            Text("Photo by \(photographer)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Flight Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Flight Information")
                        .font(.title2)
                        .fontWeight(.bold)

                    InfoRow(label: "Callsign", value: aircraft.callsign)
                    InfoRow(label: "ICAO24", value: aircraft.hex.uppercased())

                    if let squawk = aircraft.squawk {
                        InfoRow(label: "Squawk", value: squawk)
                    }

                    if let category = aircraft.category {
                        InfoRow(label: "Category", value: category)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Position & Movement
                VStack(alignment: .leading, spacing: 16) {
                    Text("Position & Movement")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let lat = aircraft.lat, let lon = aircraft.lon {
                        InfoRow(label: "Latitude", value: String(format: "%.6f°", lat))
                        InfoRow(label: "Longitude", value: String(format: "%.6f°", lon))
                    }

                    InfoRow(label: "Altitude (Baro)", value: aircraft.altBaro.map { "\($0) ft" } ?? "N/A")

                    if let altGeom = aircraft.altGeom {
                        InfoRow(label: "Altitude (Geom)", value: "\(altGeom) ft")
                    }

                    InfoRow(label: "Ground Speed", value: String(format: "%.1f kts", aircraft.groundSpeed))
                    InfoRow(label: "Heading", value: String(format: "%.1f°", aircraft.heading))

                    if let baroRate = aircraft.baroRate {
                        InfoRow(label: "Vertical Rate", value: "\(baroRate) ft/min")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Enhanced Flight Info from OpenSky
                if let flightInfo = aircraftManager.flightInfo[aircraft.hex] {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Route Information")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let origin = flightInfo.origin {
                            InfoRow(label: "Origin", value: formattedAirportString(origin))
                        }

                        if let destination = flightInfo.destination {
                            InfoRow(label: "Destination", value: formattedAirportString(destination))
                        } else if flightInfo.origin != nil {
                            HStack {
                                Text("Destination")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("In Flight")
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }

                        if let departure = flightInfo.departure {
                            InfoRow(label: "Departed", value: formatRelativeDate(departure))
                        }

                        if flightInfo.origin != nil && flightInfo.destination == nil {
                            Text("Destination updated after flight lands")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else {
                    VStack {
                        ProgressView()
                        Text("Loading flight information...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Technical Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Technical Details")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let flightInfo = aircraftManager.flightInfo[aircraft.hex], let aircraftType = flightInfo.aircraft {
                        InfoRow(label: "Type", value: AircraftTypeDirectory.name(for: aircraftType))
                    } else if let type = aircraft.type {
                        InfoRow(label: "Type", value: AircraftTypeDirectory.name(for: type))
                    }

                    if let version = aircraft.version {
                        InfoRow(label: "ADS-B Version", value: "\(version)")
                    }

                    if let nic = aircraft.nic {
                        InfoRow(label: "NIC", value: "\(nic)")
                    }

                    if let rssi = aircraft.rssi {
                        InfoRow(label: "Signal (RSSI)", value: String(format: "%.1f dBFS", rssi))
                    }

                    if let messages = aircraft.messages {
                        InfoRow(label: "Messages", value: "\(messages)")
                    }

                    if let seen = aircraft.seen {
                        InfoRow(label: "Last Seen", value: String(format: "%.1fs ago", seen))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle(aircraft.callsign)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Fetch enhanced flight info when view appears
            Task {
                await aircraftManager.fetchFlightInfo(for: aircraft, clientId: settings.openSkyClientId, clientSecret: settings.openSkyClientSecret)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let hours = Int(Date().timeIntervalSince(date) / 3600)
        if hours < 1 {
            let minutes = Int(Date().timeIntervalSince(date) / 60)
            return "\(minutes) min ago"
        } else if hours < 24 {
            return "\(hours) hr ago"
        } else {
            return formatDate(date)
        }
    }

    private func formattedAirportString(_ code: String?) -> String {
        guard let code = code, !code.isEmpty else { return "Unknown" }
        let name = AirportDirectory.name(for: code)
        if name == code.uppercased() {
            return code.uppercased()
        } else {
            return "\(code.uppercased()) — \(name)"
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
