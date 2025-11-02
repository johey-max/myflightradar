import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var aircraftManager: AircraftManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Lifetime Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Lifetime Summary")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 20) {
                        StatCard(title: "Unique Aircraft", value: "\(aircraftManager.statistics.uniqueCallsigns.count)", icon: "airplane", color: .blue)
                        StatCard(title: "Total Seen", value: "\(aircraftManager.statistics.totalAircraftSeen)", icon: "eye", color: .green)
                    }

                    StatRow(label: "Tracking Since", value: formatTrackingTime(aircraftManager.statistics.sessionStart))
                    StatRow(label: "Currently Tracking", value: "\(aircraftManager.aircraft.count) aircraft")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Altitude Distribution
                VStack(alignment: .leading, spacing: 16) {
                    Text("Altitude Distribution")
                        .font(.title2)
                        .fontWeight(.bold)

                    if aircraftManager.statistics.aircraftByAltitude.isEmpty {
                        Text("No data yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(sortedAltitudeData, id: \.key) { item in
                            AltitudeBar(range: item.key, count: item.value, total: aircraftManager.statistics.totalAircraftSeen)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Aircraft Types
                VStack(alignment: .leading, spacing: 16) {
                    Text("Most Common Types")
                        .font(.title2)
                        .fontWeight(.bold)

                    if aircraftManager.statistics.mostCommonTypes.isEmpty {
                        Text("No data yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(Array(aircraftManager.statistics.mostCommonTypes.sorted(by: { $0.value > $1.value }).prefix(5)), id: \.key) { item in
                            TypeRow(type: item.key, count: item.value)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Coverage Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("Range & Coverage")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let maxDistance = aircraftManager.coveragePoints.map({ $0.distance }).max(),
                       let avgRSSI = calculateAverageRSSI() {
                        StatRow(label: "Max Range", value: String(format: "%.1f km", maxDistance))
                        StatRow(label: "Avg Signal", value: String(format: "%.1f dBFS", avgRSSI))
                        StatRow(label: "Coverage Points", value: "\(aircraftManager.coveragePoints.count)")
                    } else {
                        Text("No coverage data yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Reset Button
                Button(action: {
                    aircraftManager.statistics = FlightStatistics()
                    aircraftManager.seenAircraftHexes.removeAll()
                    // Clear saved statistics
                    UserDefaults.standard.removeObject(forKey: "flightStatistics")
                }) {
                    Label("Reset Statistics", systemImage: "arrow.clockwise")
                        .foregroundColor(.red)
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Statistics")
    }

    private var sortedAltitudeData: [(key: String, value: Int)] {
        let order = ["0-5k ft", "5-10k ft", "10-20k ft", "20-30k ft", "30-40k ft", "40k+ ft"]
        return aircraftManager.statistics.aircraftByAltitude.sorted { first, second in
            let firstIndex = order.firstIndex(of: first.key) ?? Int.max
            let secondIndex = order.firstIndex(of: second.key) ?? Int.max
            return firstIndex < secondIndex
        }
    }

    private func formatTrackingTime(_ date: Date) -> String {
        let duration = Date().timeIntervalSince(date)
        let days = Int(duration / 86400)
        let hours = Int((duration.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h ago"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
        }
    }

    private func calculateAverageRSSI() -> Double? {
        guard !aircraftManager.coveragePoints.isEmpty else { return nil }
        let sum = aircraftManager.coveragePoints.map { $0.rssi }.reduce(0, +)
        return sum / Double(aircraftManager.coveragePoints.count)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct StatRow: View {
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

struct AltitudeBar: View {
    let range: String
    let count: Int
    let total: Int

    var body: some View {
        HStack {
            Text(range)
                .font(.subheadline)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TypeRow: View {
    let type: String
    let count: Int

    var body: some View {
        HStack {
            Text(AircraftTypeDirectory.name(for: type))
                .font(.subheadline)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
    }
}
