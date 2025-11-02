import Foundation
import CoreLocation
import Combine

// MARK: - Readsb Response Models

struct ReadsbResponse: Codable {
    let now: Double
    let messages: Int
    let aircraft: [Aircraft]
}

struct Aircraft: Codable, Identifiable {
    let hex: String
    let type: String?
    let flight: String?
    let altBaro: Int?
    let altGeom: Int?
    let gs: Double?
    let track: Double?
    let baroRate: Int?
    let squawk: String?
    let emergency: String?
    let category: String?
    let lat: Double?
    let lon: Double?
    let nic: Int?
    let rc: Int?
    let seenPos: Double?
    let seen: Double?
    let rssi: Double?
    let messages: Int?
    let version: Int?

    var id: String { hex }

    var callsign: String {
        flight?.trimmingCharacters(in: .whitespaces) ?? hex.uppercased()
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lon = lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var altitude: Int {
        altBaro ?? altGeom ?? 0
    }

    var groundSpeed: Double {
        gs ?? 0
    }

    var heading: Double {
        track ?? 0
    }

    var aircraftType: String {
        if let type = type, !type.isEmpty, type.lowercased() != "adsb_icao" {
            return AircraftTypeDirectory.name(for: type)
        } else if let category = category {
            return AircraftTypeDirectory.name(for: category)
        } else {
            return "Unknown"
        }
    }

    enum CodingKeys: String, CodingKey {
        case hex, type, flight, squawk, emergency, category, lat, lon, nic, rc, seen, rssi, messages, version
        case altBaro = "alt_baro"
        case altGeom = "alt_geom"
        case gs
        case track
        case baroRate = "baro_rate"
        case seenPos = "seen_pos"
    }
}

// MARK: - OpenSky Network Models

struct OpenSkyResponse: Codable {
    let time: Int
    let states: [[OpenSkyValue]]?
}

enum OpenSkyValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}

struct FlightInfo {
    let icao24: String
    let callsign: String?
    let origin: String?
    let destination: String?
    let departure: Date?
    let arrival: Date?
    let aircraft: String?
    let airline: String?
}

// MARK: - Aircraft Trail

struct TrailPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let altitude: Int
    let timestamp: Date
}

struct AircraftTrail {
    let hex: String
    var points: [TrailPoint]
    let maxPoints: Int = 500 // Keep last 500 positions

    mutating func addPoint(coordinate: CLLocationCoordinate2D, altitude: Int) {
        let point = TrailPoint(coordinate: coordinate, altitude: altitude, timestamp: Date())
        points.append(point)

        // Keep only recent points
        if points.count > maxPoints {
            points.removeFirst(points.count - maxPoints)
        }
    }
}

// MARK: - Aircraft Photo

struct AircraftPhoto: Codable {
    let photoUrl: String?
    let photographer: String?
    let registration: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case photoUrl = "thumbnail_large"
        case photographer
        case registration
        case type
    }
}

// MARK: - Statistics

struct FlightStatistics: Codable {
    var totalAircraftSeen: Int = 0
    var totalFlights: Int = 0
    var sessionStart: Date = Date()
    var aircraftByAltitude: [String: Int] = [:] // altitude range -> count
    var mostCommonTypes: [String: Int] = [:] // aircraft type -> count
    var uniqueCallsigns: Set<String> = []

    mutating func recordAircraft(_ aircraft: Aircraft) {
        totalAircraftSeen += 1

        if let callsign = aircraft.flight?.trimmingCharacters(in: .whitespaces), !callsign.isEmpty {
            uniqueCallsigns.insert(callsign)
        }

        // Track altitude distribution
        let altitudeRange = getAltitudeRange(aircraft.altitude)
        aircraftByAltitude[altitudeRange, default: 0] += 1

        // Track aircraft types - only if we have valid type data
        let type = aircraft.aircraftType
        if type != "Unknown" && type != "N/A" && !type.isEmpty {
            mostCommonTypes[type, default: 0] += 1
        }
    }

    private func getAltitudeRange(_ altitude: Int) -> String {
        switch altitude {
        case 0..<5000: return "0-5k ft"
        case 5000..<10000: return "5-10k ft"
        case 10000..<20000: return "10-20k ft"
        case 20000..<30000: return "20-30k ft"
        case 30000..<40000: return "30-40k ft"
        default: return "40k+ ft"
        }
    }

    // Persistence
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "flightStatistics")
        }
    }

    static func load() -> FlightStatistics {
        if let data = UserDefaults.standard.data(forKey: "flightStatistics"),
           let decoded = try? JSONDecoder().decode(FlightStatistics.self, from: data) {
            return decoded
        }
        return FlightStatistics()
    }
}

// MARK: - Coverage/Range

struct CoveragePoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let rssi: Double
    let distance: Double
    let timestamp: Date
}

// MARK: - App Settings

class AppSettings: ObservableObject {
    @Published var serverAddress: String {
        didSet {
            UserDefaults.standard.set(serverAddress, forKey: "serverAddress")
        }
    }

    @Published var useLocalServer: Bool {
        didSet {
            UserDefaults.standard.set(useLocalServer, forKey: "useLocalServer")
        }
    }

    // OpenSky Network OAuth2 credentials
    let openSkyClientId = "jlangstroth-api-client"
    let openSkyClientSecret = "Y1IevcSRmEEadFULI6piEhLNJ6fO7r06"

    init() {
        self.serverAddress = UserDefaults.standard.string(forKey: "serverAddress") ?? "100.87.34.53:8081"
        self.useLocalServer = UserDefaults.standard.bool(forKey: "useLocalServer")
    }

    var baseURL: String {
        let address = serverAddress.hasPrefix("http") ? serverAddress : "http://\(serverAddress)"
        return address
    }
}
