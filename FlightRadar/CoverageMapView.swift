import SwiftUI
import MapKit

struct CoverageMapView: View {
    @EnvironmentObject var aircraftManager: AircraftManager
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.284043, longitude: -124.792703),
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
        )
    )
    @State private var showLegend = true
    @State private var selectedRangeFilter: RangeFilter = .all

    enum RangeFilter: String, CaseIterable {
        case all = "All"
        case strong = "Strong"
        case medium = "Medium"
        case weak = "Weak"
    }

    var filteredCoveragePoints: [CoveragePoint] {
        aircraftManager.coveragePoints.filter { point in
            switch selectedRangeFilter {
            case .all:
                return true
            case .strong:
                return point.rssi > -15
            case .medium:
                return point.rssi > -25 && point.rssi <= -15
            case .weak:
                return point.rssi <= -25
            }
        }
    }

    var body: some View {
        ZStack {
            Map(position: $position) {
                // Receiver location marker
                Annotation("Your Receiver", coordinate: CLLocationCoordinate2D(latitude: 49.284043, longitude: -124.792703)) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 20, height: 20)
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.white)
                            .font(.caption2)
                    }
                }

                // Range rings (draw first so they're behind coverage points)
                ForEach([50000.0, 100000.0, 150000.0, 200000.0, 250000.0], id: \.self) { radius in
                    MapCircle(center: CLLocationCoordinate2D(latitude: 49.284043, longitude: -124.792703), radius: radius)
                        .foregroundStyle(.clear)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                }

                // Coverage points as circles
                ForEach(filteredCoveragePoints) { point in
                    MapCircle(center: point.coordinate, radius: 1000) // 1km circles
                        .foregroundStyle(signalColor(rssi: point.rssi).opacity(0.3))
                        .stroke(signalColor(rssi: point.rssi), lineWidth: 1)
                }
            }
            .ignoresSafeArea()

            // Controls overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coverage Map")
                            .font(.headline)
                        Text("\(filteredCoveragePoints.count) points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)

                    Spacer()

                    // Filter picker
                    Picker("Filter", selection: $selectedRangeFilter) {
                        ForEach(RangeFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)

                    Button {
                        showLegend.toggle()
                    } label: {
                        Image(systemName: showLegend ? "eye.fill" : "eye.slash")
                            .font(.title3)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                // Legend
                if showLegend {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Signal Strength Legend")
                            .font(.headline)

                        HStack(spacing: 16) {
                            LegendItem(color: .green, label: "Strong", range: "> -15 dBFS")
                            LegendItem(color: .yellow, label: "Medium", range: "-15 to -25")
                            LegendItem(color: .orange, label: "Weak", range: "-25 to -35")
                            LegendItem(color: .red, label: "Very Weak", range: "< -35")
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            if let maxDistance = aircraftManager.coveragePoints.map({ $0.distance }).max() {
                                Text("Max Range: \(String(format: "%.1f km", maxDistance))")
                                    .font(.caption)
                            }

                            Text("Gray rings: 50km intervals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    // Clear coverage data
                    aircraftManager.coveragePoints.removeAll()
                }
            }
        }
    }

    private func signalColor(rssi: Double) -> Color {
        switch rssi {
        case -15...0:
            return .green
        case -25 ... -15:
            return .yellow
        case -35 ... -25:
            return .orange
        default:
            return .red
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let range: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            Text(range)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// Preview
struct CoverageMapView_Previews: PreviewProvider {
    static var previews: some View {
        CoverageMapView()
            .environmentObject(AircraftManager())
    }
}
