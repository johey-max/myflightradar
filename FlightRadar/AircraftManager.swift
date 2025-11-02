import Foundation
import _LocationEssentials
import Combine
import SwiftUI
import WidgetKit

@MainActor
class AircraftManager: ObservableObject {
    @Published var aircraft: [Aircraft] = []
    @Published var selectedAircraft: Aircraft?
    @Published var flightInfo: [String: FlightInfo] = [:]
    @Published var aircraftPhotos: [String: AircraftPhoto] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdate: Date?

    // Trail tracking
    @Published var trails: [String: AircraftTrail] = [:]
    @Published var showTrails = true

    // Statistics
    @Published var statistics = FlightStatistics.load() {
        didSet {
            // Debounce saving - only save every 10 seconds
            statisticsSaveTask?.cancel()
            statisticsSaveTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                statistics.save()
            }
        }
    }

    // Coverage/Range tracking
    @Published var coveragePoints: [CoveragePoint] = []

    private var updateTimer: Timer?
    private let networkService = NetworkService.shared
    var seenAircraftHexes: Set<String> = []
    private var statisticsSaveTask: Task<Void, Never>?
    private var lastFlightInfoFetch: [String: Date] = [:]
    private var updateCount = 0

    func startUpdating(serverURL: String, interval: TimeInterval = 2.0) {
        stopUpdating()

        // Initial fetch
        Task {
            await fetchAircraft(from: serverURL)
        }

        // Set up periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchAircraft(from: serverURL)
            }
        }
    }

    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    nonisolated deinit {
        // Timer invalidation is thread-safe
        updateTimer?.invalidate()
    }

    func cleanup() {
        // Clean up old data to free memory
        let cutoffDate = Date().addingTimeInterval(-3600) // 1 hour ago

        // Remove old flight info for aircraft no longer visible
        let currentHexes = Set(aircraft.map { $0.hex })
        flightInfo = flightInfo.filter { currentHexes.contains($0.key) }
        aircraftPhotos = aircraftPhotos.filter { currentHexes.contains($0.key) }

        // Remove old coverage points
        coveragePoints.removeAll { $0.timestamp < cutoffDate }

        // Clean fetch throttle cache
        lastFlightInfoFetch = lastFlightInfoFetch.filter { Date().timeIntervalSince($0.value) < 300 }
    }

    func fetchAircraft(from serverURL: String) async {
        errorMessage = nil

        do {
            let response = try await networkService.fetchAircraft(from: serverURL)
            aircraft = response.aircraft.filter { $0.lat != nil && $0.lon != nil }
            lastUpdate = Date()

            // Update trails and statistics (optimized loop)
            let receiverLocation = CLLocation(latitude: 49.284043, longitude: -124.792703)
            var newCoveragePoints: [CoveragePoint] = []

            for aircraft in aircraft {
                // Track trails
                if let coordinate = aircraft.coordinate {
                    if trails[aircraft.hex] == nil {
                        trails[aircraft.hex] = AircraftTrail(hex: aircraft.hex, points: [])
                    }
                    trails[aircraft.hex]?.addPoint(coordinate: coordinate, altitude: aircraft.altitude)
                }

                // Track statistics (only for new aircraft with valid type)
                if !seenAircraftHexes.contains(aircraft.hex) {
                    let aircraftType = aircraft.aircraftType
                    // Only record if we have valid type data
                    if aircraftType != "Unknown" && aircraftType != "N/A" && !aircraftType.isEmpty {
                        statistics.recordAircraft(aircraft)
                        seenAircraftHexes.insert(aircraft.hex)
                    }
                    // If type is unknown, we'll catch it on next update when type might be available
                }

                // Track coverage/range data (batch collection)
                if let coordinate = aircraft.coordinate, let rssi = aircraft.rssi {
                    let aircraftLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let distance = receiverLocation.distance(from: aircraftLocation) / 1000.0 // km

                    newCoveragePoints.append(CoveragePoint(
                        coordinate: coordinate,
                        rssi: rssi,
                        distance: distance,
                        timestamp: Date()
                    ))
                }
            }

            // Batch update coverage points
            coveragePoints.append(contentsOf: newCoveragePoints)
            if coveragePoints.count > 1000 {
                coveragePoints.removeFirst(coveragePoints.count - 1000)
            }

            // Clean up old trails (aircraft no longer visible)
            let currentHexes = Set(aircraft.map { $0.hex })
            let trailsToRemove = trails.keys.filter { !currentHexes.contains($0) }
            for hex in trailsToRemove {
                // Keep trails for 5 minutes after aircraft disappears
                if let lastPoint = trails[hex]?.points.last,
                   Date().timeIntervalSince(lastPoint.timestamp) > 300 {
                    trails.removeValue(forKey: hex)
                }
            }

            // Update widget with new data
            updateWidgetData()

            // Periodic cleanup (every 50 updates = ~100 seconds at 2s interval)
            updateCount += 1
            if updateCount >= 50 {
                updateCount = 0
                cleanup()
            }

        } catch {
            errorMessage = "Failed to fetch aircraft: \(error.localizedDescription)"
        }
    }

    func fetchFlightInfo(for aircraft: Aircraft, clientId: String, clientSecret: String) async {
        // Check if we already have cached info
        if flightInfo[aircraft.hex] != nil {
            return
        }

        // Throttle API calls - only fetch once per aircraft per 60 seconds
        if let lastFetch = lastFlightInfoFetch[aircraft.hex],
           Date().timeIntervalSince(lastFetch) < 60 {
            return
        }

        lastFlightInfoFetch[aircraft.hex] = Date()

        do {
            if let info = try await networkService.fetchFlightInfo(icao24: aircraft.hex, clientId: clientId, clientSecret: clientSecret) {
                flightInfo[aircraft.hex] = info
            }
        } catch {
            // Silently fail to avoid console spam
            lastFlightInfoFetch.removeValue(forKey: aircraft.hex) // Allow retry
        }
    }

    func fetchAircraftPhoto(for aircraft: Aircraft) async {
        // Check if we already have cached photo
        if aircraftPhotos[aircraft.hex] != nil {
            return
        }

        do {
            if let photo = try await networkService.fetchAircraftPhoto(hex: aircraft.hex) {
                aircraftPhotos[aircraft.hex] = photo
            }
        } catch {
            print("Error fetching photo for \(aircraft.hex): \(error)")
        }
    }

    func selectAircraft(_ aircraft: Aircraft, openSkyClientId: String, openSkyClientSecret: String) {
        selectedAircraft = aircraft

        // Fetch enhanced flight info and photo
        Task {
            await fetchFlightInfo(for: aircraft, clientId: openSkyClientId, clientSecret: openSkyClientSecret)
            await fetchAircraftPhoto(for: aircraft)
        }
    }

    // MARK: - Widget Data Sharing

    func updateWidgetData() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.joge.FlightRadar")

        // Save aircraft count
        sharedDefaults?.set(aircraft.count, forKey: "aircraftCount")

        // Save last update timestamp
        if let lastUpdate = lastUpdate {
            sharedDefaults?.set(lastUpdate.timeIntervalSince1970, forKey: "lastUpdate")
        }

        // Find nearest aircraft
        if let nearest = findNearestAircraft() {
            let nearestData = NearestAircraftData(
                callsign: nearest.aircraft.callsign,
                altitude: nearest.aircraft.altitude,
                distance: nearest.distance,
                heading: nearest.aircraft.heading
            )

            if let encoded = try? JSONEncoder().encode(nearestData) {
                sharedDefaults?.set(encoded, forKey: "nearestAircraft")
            }
        } else {
            sharedDefaults?.removeObject(forKey: "nearestAircraft")
        }

        // Save aircraft data for map widget (limit to 10 closest aircraft)
        let widgetAircraft = aircraft
            .prefix(10)
            .compactMap { aircraft -> WidgetAircraftData? in
                guard let lat = aircraft.lat, let lon = aircraft.lon else { return nil }

                let origin = flightInfo[aircraft.hex]?.origin

                return WidgetAircraftData(
                    id: aircraft.hex,
                    callsign: aircraft.callsign,
                    latitude: lat,
                    longitude: lon,
                    altitude: aircraft.altitude,
                    heading: aircraft.heading,
                    origin: origin,
                    aircraftType: aircraft.aircraftType
                )
            }

        if let encoded = try? JSONEncoder().encode(widgetAircraft) {
            sharedDefaults?.set(encoded, forKey: "widgetAircraft")
        }

        // Tell widgets to reload
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func findNearestAircraft() -> (aircraft: Aircraft, distance: Double)? {
        let receiverLocation = CLLocation(latitude: 49.284043, longitude: -124.792703)

        var nearest: (aircraft: Aircraft, distance: Double)? = nil

        for aircraft in aircraft {
            guard let coordinate = aircraft.coordinate else { continue }

            let aircraftLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = receiverLocation.distance(from: aircraftLocation) / 1000.0 // km

            if nearest == nil || distance < nearest!.distance {
                nearest = (aircraft, distance)
            }
        }

        return nearest
    }
}

// MARK: - Widget Data Model

struct NearestAircraftData: Codable {
    let callsign: String
    let altitude: Int
    let distance: Double
    let heading: Double
}

struct WidgetAircraftData: Codable {
    let id: String
    let callsign: String
    let latitude: Double
    let longitude: Double
    let altitude: Int
    let heading: Double
    let origin: String?
    let aircraftType: String?
}
