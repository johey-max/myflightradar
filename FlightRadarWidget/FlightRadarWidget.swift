//
//  FlightRadarWidget.swift
//  FlightRadarWidget
//
//  Created by Joseph Langstroth on 2025-11-01.
//

import WidgetKit
import SwiftUI
import MapKit

// MARK: - Aircraft Type Directory

final class WidgetAircraftTypeDirectory {
    static let shared = WidgetAircraftTypeDirectory()

    private(set) var codeToName: [String: String] = [:]

    private init() {
        loadAircraftTypes()
    }

    private func loadAircraftTypes() {
        // Boeing
        codeToName["B77W"] = "Boeing 777-300ER"
        codeToName["B77L"] = "Boeing 777-200LR"
        codeToName["B772"] = "Boeing 777-200"
        codeToName["B773"] = "Boeing 777-300"
        codeToName["B788"] = "Boeing 787-8"
        codeToName["B789"] = "Boeing 787-9"
        codeToName["B78X"] = "Boeing 787-10"
        codeToName["B738"] = "Boeing 737-800"
        codeToName["B737"] = "Boeing 737-700"
        codeToName["B739"] = "Boeing 737-900"
        codeToName["B38M"] = "Boeing 737 MAX 8"
        codeToName["B39M"] = "Boeing 737 MAX 9"
        codeToName["B744"] = "Boeing 747-400"
        codeToName["B748"] = "Boeing 747-8"
        codeToName["B752"] = "Boeing 757-200"
        codeToName["B753"] = "Boeing 757-300"
        codeToName["B762"] = "Boeing 767-200"
        codeToName["B763"] = "Boeing 767-300"
        codeToName["B764"] = "Boeing 767-400"

        // Airbus
        codeToName["A320"] = "Airbus A320"
        codeToName["A321"] = "Airbus A321"
        codeToName["A319"] = "Airbus A319"
        codeToName["A20N"] = "Airbus A320neo"
        codeToName["A21N"] = "Airbus A321neo"
        codeToName["A332"] = "Airbus A330-200"
        codeToName["A333"] = "Airbus A330-300"
        codeToName["A339"] = "Airbus A330-900neo"
        codeToName["A359"] = "Airbus A350-900"
        codeToName["A35K"] = "Airbus A350-1000"
        codeToName["A388"] = "Airbus A380-800"

        // Short/generic codes
        codeToName["A3"] = "Airbus A330"
        codeToName["A5"] = "Airbus A350"
        codeToName["A350"] = "Airbus A350"
        codeToName["A330"] = "Airbus A330"
        codeToName["B77"] = "Boeing 777"
        codeToName["B78"] = "Boeing 787"
        codeToName["B73"] = "Boeing 737"

        // Embraer
        codeToName["E190"] = "Embraer E190"
        codeToName["E195"] = "Embraer E195"
        codeToName["E170"] = "Embraer E170"
        codeToName["E175"] = "Embraer E175"
        codeToName["E145"] = "Embraer ERJ-145"

        // Bombardier
        codeToName["CRJ9"] = "Bombardier CRJ-900"
        codeToName["CRJ7"] = "Bombardier CRJ-700"
        codeToName["CRJ2"] = "Bombardier CRJ-200"
        codeToName["DH8D"] = "Bombardier Q400"
        codeToName["DH8C"] = "Bombardier Q300"

        // Regional
        codeToName["AT72"] = "ATR 72"
        codeToName["AT76"] = "ATR 72-600"

        // Cargo
        codeToName["B77F"] = "Boeing 777F"
        codeToName["B74F"] = "Boeing 747F"
        codeToName["MD11"] = "McDonnell Douglas MD-11"

        // Small
        codeToName["C172"] = "Cessna 172"
        codeToName["C208"] = "Cessna 208"
        codeToName["PC12"] = "Pilatus PC-12"
        codeToName["SR22"] = "Cirrus SR22"
    }

    static func name(for code: String?) -> String {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !code.isEmpty else { return "Unknown" }
        return shared.codeToName[code] ?? code
    }
}

// MARK: - Airport Directory

final class WidgetAirportDirectory {
    static let shared = WidgetAirportDirectory()

    private(set) var codeToName: [String: String] = [:]

    private init() {
        loadAirportDatabase()
    }

    private func loadAirportDatabase() {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "csv") else {
            print("❌ Widget: Could not find airports.csv in bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            return
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ Widget: Could not read airports.csv from bundle")
            return
        }

        print("✅ Widget: Loading airports.csv, content length: \(content.count)")
        var loadedCount = 0

        for line in content.components(separatedBy: .newlines) {
            // OpenFlights CSV format: ID,"Name","City","Country","IATA","ICAO",lat,lon,...
            let columns = line.split(separator: ",", maxSplits: 8, omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
            if columns.count >= 6 {
                let name = columns[1]
                let iata = columns[4].uppercased()
                let icao = columns[5].uppercased()

                if !iata.isEmpty && iata != "\\N" {
                    codeToName[iata] = name
                    loadedCount += 1
                }
                if !icao.isEmpty && icao != "\\N" {
                    codeToName[icao] = name
                    loadedCount += 1
                }
            }
        }

        print("✅ Widget: Loaded \(loadedCount) airport codes")
        print("✅ Widget: Sample - KSEA = \(codeToName["KSEA"] ?? "NOT FOUND")")
    }

    static func name(for code: String?) -> String {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !code.isEmpty else { return "Unknown" }
        return shared.codeToName[code] ?? code
    }
}

// MARK: - Widget Entry

struct FlightEntry: TimelineEntry {
    let date: Date
    let aircraftCount: Int
    let nearestAircraft: NearestAircraftData?
    let lastUpdate: Date?
    let aircraft: [WidgetAircraftData]
    let mapSnapshot: UIImage?
}

struct NearestAircraftData: Codable {
    let callsign: String
    let altitude: Int
    let distance: Double
    let heading: Double
}

struct WidgetAircraftData: Codable, Identifiable {
    let id: String // hex
    let callsign: String
    let latitude: Double
    let longitude: Double
    let altitude: Int
    let heading: Double
    let origin: String?
    let aircraftType: String?
}

// MARK: - Widget Data Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> FlightEntry {
        FlightEntry(
            date: Date(),
            aircraftCount: 12,
            nearestAircraft: NearestAircraftData(
                callsign: "UAL123",
                altitude: 35000,
                distance: 42.5,
                heading: 180
            ),
            lastUpdate: Date(),
            aircraft: [
                WidgetAircraftData(id: "a12345", callsign: "UAL123", latitude: 49.5, longitude: -124.5, altitude: 35000, heading: 180, origin: "KSEA", aircraftType: "B77W"),
                WidgetAircraftData(id: "b67890", callsign: "DAL456", latitude: 49.3, longitude: -124.8, altitude: 28000, heading: 90, origin: "KYVR", aircraftType: "A320")
            ],
            mapSnapshot: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FlightEntry) -> ()) {
        let baseEntry = loadData()

        Task {
            let mapImage = await generateMapSnapshot(for: baseEntry.aircraft, size: context.displaySize)
            let entry = FlightEntry(
                date: baseEntry.date,
                aircraftCount: baseEntry.aircraftCount,
                nearestAircraft: baseEntry.nearestAircraft,
                lastUpdate: baseEntry.lastUpdate,
                aircraft: baseEntry.aircraft,
                mapSnapshot: mapImage
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlightEntry>) -> ()) {
        let baseEntry = loadData()

        // Generate map snapshot
        Task {
            let mapImage = await generateMapSnapshot(for: baseEntry.aircraft, size: context.displaySize)
            let entry = FlightEntry(
                date: baseEntry.date,
                aircraftCount: baseEntry.aircraftCount,
                nearestAircraft: baseEntry.nearestAircraft,
                lastUpdate: baseEntry.lastUpdate,
                aircraft: baseEntry.aircraft,
                mapSnapshot: mapImage
            )

            // Update every 60 seconds (saves battery)
            let nextUpdate = Calendar.current.date(byAdding: .second, value: 60, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func generateMapSnapshot(for aircraft: [WidgetAircraftData], size: CGSize) async -> UIImage? {
        let receiverLat = 49.284043
        let receiverLon = -124.792703

        let minLat = min(receiverLat, aircraft.map { $0.latitude }.min() ?? receiverLat) - 0.3
        let maxLat = max(receiverLat, aircraft.map { $0.latitude }.max() ?? receiverLat) + 0.3
        let minLon = min(receiverLon, aircraft.map { $0.longitude }.min() ?? receiverLon) - 0.3
        let maxLon = max(receiverLon, aircraft.map { $0.longitude }.max() ?? receiverLon) + 0.3

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(0.5, maxLat - minLat),
            longitudeDelta: max(0.5, maxLon - minLon)
        )

        let region = MKCoordinateRegion(center: center, span: span)

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.mapType = .standard

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            print("✅ Widget: Map snapshot generated successfully")
            return snapshot.image
        } catch {
            print("❌ Widget: Failed to generate map: \(error)")
            return nil
        }
    }

    private func loadData() -> FlightEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.joge.FlightRadar")

        let aircraftCount = sharedDefaults?.integer(forKey: "aircraftCount") ?? 0
        let lastUpdateTimestamp = sharedDefaults?.double(forKey: "lastUpdate") ?? 0
        let lastUpdate = lastUpdateTimestamp > 0 ? Date(timeIntervalSince1970: lastUpdateTimestamp) : nil

        var nearestAircraft: NearestAircraftData? = nil
        if let nearestData = sharedDefaults?.data(forKey: "nearestAircraft") {
            nearestAircraft = try? JSONDecoder().decode(NearestAircraftData.self, from: nearestData)
        }

        var aircraft: [WidgetAircraftData] = []
        if let aircraftData = sharedDefaults?.data(forKey: "widgetAircraft") {
            aircraft = (try? JSONDecoder().decode([WidgetAircraftData].self, from: aircraftData)) ?? []
            print("✅ Widget: Loaded \(aircraft.count) aircraft from shared data")
            if let first = aircraft.first {
                print("✅ Widget: First aircraft: \(first.callsign), origin: \(first.origin ?? "nil")")
            }
        } else {
            print("❌ Widget: No aircraft data in shared defaults")
        }

        return FlightEntry(
            date: Date(),
            aircraftCount: aircraftCount,
            nearestAircraft: nearestAircraft,
            lastUpdate: lastUpdate,
            aircraft: aircraft,
            mapSnapshot: nil
        )
    }
}

// MARK: - Widget Views

struct FlightRadarWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: FlightEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "airplane")
                    .font(.title3)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.aircraftCount)")
                    .font(.system(size: 48, weight: .bold))
                Text("Aircraft")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if let update = entry.lastUpdate {
                Text(update, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text("No data")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .foregroundColor(.white)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct MediumWidgetView: View {
    let entry: FlightEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Aircraft count
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "airplane")
                    .font(.title2)

                Text("\(entry.aircraftCount)")
                    .font(.system(size: 42, weight: .bold))

                Text("Aircraft")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if let update = entry.lastUpdate {
                    Text(update, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(Color.white.opacity(0.3))

            // Right side - Nearest aircraft
            if let nearest = entry.nearestAircraft {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearest")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Text(nearest.callsign)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                        Text("\(nearest.altitude) ft")
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(String(format: "%.1f km", nearest.distance))
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "airplane")
                            .font(.caption2)
                            .rotationEffect(.degrees(nearest.heading))
                        Text("\(Int(nearest.heading))°")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack {
                    Image(systemName: "airplane.departure")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.5))
                    Text("No aircraft")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .foregroundColor(.white)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct LargeWidgetView: View {
    let entry: FlightEntry

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Flight Radar")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(entry.aircraftCount) Aircraft")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                if let update = entry.lastUpdate {
                    Text(update, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Map
            if !entry.aircraft.isEmpty {
                MapView(aircraft: entry.aircraft, mapSnapshot: entry.mapSnapshot)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "airplane.departure")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                    Text("No aircraft tracking")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                }
            }
        }
        .foregroundColor(.white)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct MapView: View {
    let aircraft: [WidgetAircraftData]
    let mapSnapshot: UIImage?

    var mapRegion: MKCoordinateRegion {
        let receiverLat = 49.284043
        let receiverLon = -124.792703

        let minLat = min(receiverLat, aircraft.map { $0.latitude }.min() ?? receiverLat) - 0.3
        let maxLat = max(receiverLat, aircraft.map { $0.latitude }.max() ?? receiverLat) + 0.3
        let minLon = min(receiverLon, aircraft.map { $0.longitude }.min() ?? receiverLon) - 0.3
        let maxLon = max(receiverLon, aircraft.map { $0.longitude }.max() ?? receiverLon) + 0.3

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(0.5, maxLat - minLat),
            longitudeDelta: max(0.5, maxLon - minLon)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        GeometryReader { geometry in
            let region = mapRegion

            ZStack {
                // Real map background from Apple Maps
                if let image = mapSnapshot {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Fallback if map not loaded
                    LinearGradient(
                        colors: [
                            Color(red: 0.7, green: 0.85, blue: 0.95),
                            Color(red: 0.6, green: 0.75, blue: 0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                // Receiver marker
                let receiverCoord = CLLocationCoordinate2D(latitude: 49.284043, longitude: -124.792703)
                let receiverPoint = coordinateToPoint(receiverCoord, in: region, size: geometry.size)

                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                    Circle()
                        .stroke(Color.white, lineWidth: 2.5)
                        .frame(width: 16, height: 16)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                }
                .position(receiverPoint)

                // Aircraft markers
                ForEach(aircraft) { plane in
                    let coord = CLLocationCoordinate2D(latitude: plane.latitude, longitude: plane.longitude)
                    let point = coordinateToPoint(coord, in: region, size: geometry.size)

                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 26, height: 26)
                                .shadow(color: .black.opacity(0.5), radius: 3)
                            Image(systemName: "airplane")
                                .font(.system(size: 13, weight: .bold))
                                .rotationEffect(.degrees(plane.heading - 90))
                                .foregroundColor(altitudeColor(plane.altitude))
                        }

                        VStack(spacing: 0) {
                            Text(plane.callsign)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                            if let type = plane.aircraftType {
                                Text(WidgetAircraftTypeDirectory.name(for: type))
                                    .font(.system(size: 6, weight: .semibold))
                                    .foregroundColor(.yellow)
                            }
                            if let origin = plane.origin {
                                let airportName = WidgetAirportDirectory.name(for: origin)
                                if airportName != origin {
                                    Text(airportName)
                                        .font(.system(size: 5, weight: .medium))
                                        .foregroundColor(.cyan)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.4)
                                } else {
                                    Text(origin)
                                        .font(.system(size: 6, weight: .semibold))
                                        .foregroundColor(.cyan)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .frame(maxWidth: 85)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.black.opacity(0.85))
                        )
                    }
                    .position(point)
                }
            }
        }
    }

    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in region: MKCoordinateRegion, size: CGSize) -> CGPoint {
        let latDelta = region.span.latitudeDelta
        let lonDelta = region.span.longitudeDelta

        let x = (coordinate.longitude - (region.center.longitude - lonDelta / 2)) / lonDelta * size.width
        let y = ((region.center.latitude + latDelta / 2) - coordinate.latitude) / latDelta * size.height

        return CGPoint(x: x, y: y)
    }

    private func altitudeColor(_ altitude: Int) -> Color {
        if altitude < 5000 {
            return .green
        } else if altitude < 20000 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Widget Configuration

struct FlightRadarWidget: Widget {
    let kind: String = "FlightRadarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FlightRadarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Flight Radar")
        .description("Track aircraft in your area")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

struct FlightRadarWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleAircraft = [
            WidgetAircraftData(id: "a12345", callsign: "UAL123", latitude: 49.5, longitude: -124.5, altitude: 35000, heading: 180, origin: "KSEA", aircraftType: "B77W"),
            WidgetAircraftData(id: "b67890", callsign: "DAL456", latitude: 49.3, longitude: -124.8, altitude: 28000, heading: 90, origin: "CYVR", aircraftType: "A320"),
            WidgetAircraftData(id: "c11111", callsign: "AAL789", latitude: 49.1, longitude: -124.3, altitude: 15000, heading: 270, origin: "KLAX", aircraftType: "B738")
        ]

        Group {
            FlightRadarWidgetEntryView(entry: FlightEntry(
                date: Date(),
                aircraftCount: 12,
                nearestAircraft: NearestAircraftData(
                    callsign: "UAL123",
                    altitude: 35000,
                    distance: 42.5,
                    heading: 180
                ),
                lastUpdate: Date(),
                aircraft: sampleAircraft,
                mapSnapshot: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            FlightRadarWidgetEntryView(entry: FlightEntry(
                date: Date(),
                aircraftCount: 8,
                nearestAircraft: NearestAircraftData(
                    callsign: "DAL456",
                    altitude: 28000,
                    distance: 67.2,
                    heading: 315
                ),
                lastUpdate: Date(),
                aircraft: sampleAircraft,
                mapSnapshot: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            FlightRadarWidgetEntryView(entry: FlightEntry(
                date: Date(),
                aircraftCount: 3,
                nearestAircraft: NearestAircraftData(
                    callsign: "UAL123",
                    altitude: 35000,
                    distance: 42.5,
                    heading: 180
                ),
                lastUpdate: Date(),
                aircraft: sampleAircraft,
                mapSnapshot: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
