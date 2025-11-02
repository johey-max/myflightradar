import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()

    private var cachedAccessToken: String?
    private var tokenExpiresAt: Date?

    private init() {}

    // Fetch aircraft data from readsb
    func fetchAircraft(from baseURL: String) async throws -> ReadsbResponse {
        let urlString = "\(baseURL)/data/aircraft.json"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ReadsbResponse.self, from: data)
    }

    // Get OAuth2 access token from OpenSky Network
    private func getOpenSkyAccessToken(clientId: String, clientSecret: String) async throws -> String {
        // Check if we have a valid cached token
        if let token = cachedAccessToken,
           let expiresAt = tokenExpiresAt,
           Date() < expiresAt {
            return token
        }

        // Request new token
        guard let url = URL(string: "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "grant_type=client_credentials&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        struct TokenResponse: Codable {
            let access_token: String
            let expires_in: Int
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Cache the token
        cachedAccessToken = tokenResponse.access_token
        tokenExpiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 60)) // Refresh 60s early

        return tokenResponse.access_token
    }

    // Fetch enhanced flight info from OpenSky Network with OAuth2
    func fetchFlightInfo(icao24: String, clientId: String, clientSecret: String) async throws -> FlightInfo? {
        // Get access token
        let accessToken = try await getOpenSkyAccessToken(clientId: clientId, clientSecret: clientSecret)

        // OpenSky Network API endpoint for flight details
        let urlString = "https://opensky-network.org/api/flights/aircraft?icao24=\(icao24.lowercased())&begin=\(Int(Date().timeIntervalSince1970) - 86400)&end=\(Int(Date().timeIntervalSince1970))"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        // Create request with Bearer token
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // OpenSky returns 404 if no flights found
        if httpResponse.statusCode == 404 {
            return nil
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        // Parse the flight data
        let flights = try JSONDecoder().decode([OpenSkyFlight].self, from: data)

        guard let latestFlight = flights.first else {
            return nil
        }

        return FlightInfo(
            icao24: icao24,
            callsign: latestFlight.callsign?.trimmingCharacters(in: .whitespaces),
            origin: latestFlight.estDepartureAirport,
            destination: latestFlight.estArrivalAirport,
            departure: latestFlight.firstSeen.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            arrival: latestFlight.lastSeen.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            aircraft: nil,
            airline: nil
        )
    }

    // Fetch aircraft photo from database (using hex code)
    func fetchAircraftPhoto(hex: String) async throws -> AircraftPhoto? {
        // Using a free aircraft photo API - JetPhotos API alternative
        // Note: This is a simplified example. You may need to use registration number instead
        let urlString = "https://api.planespotters.net/pub/photos/hex/\(hex.uppercased())"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // Return nil if no photo found
        if httpResponse.statusCode == 404 {
            return nil
        }

        guard httpResponse.statusCode == 200 else {
            return nil
        }

        // Parse photo data
        struct PhotoResponse: Codable {
            let photos: [PhotoData]?

            struct PhotoData: Codable {
                let thumbnail_large: ThumbnailData?
                let photographer: String?

                struct ThumbnailData: Codable {
                    let src: String?
                }
            }
        }

        let photoResponse = try? JSONDecoder().decode(PhotoResponse.self, from: data)

        if let photo = photoResponse?.photos?.first,
           let thumbnailUrl = photo.thumbnail_large?.src {
            return AircraftPhoto(
                photoUrl: thumbnailUrl,
                photographer: photo.photographer,
                registration: nil,
                type: nil
            )
        }

        return nil
    }
}

// MARK: - OpenSky Flight Model

struct OpenSkyFlight: Codable {
    let icao24: String
    let firstSeen: Int?
    let estDepartureAirport: String?
    let lastSeen: Int?
    let estArrivalAirport: String?
    let callsign: String?
    let estDepartureAirportHorizDistance: Int?
    let estDepartureAirportVertDistance: Int?
    let estArrivalAirportHorizDistance: Int?
    let estArrivalAirportVertDistance: Int?
    let departureAirportCandidatesCount: Int?
    let arrivalAirportCandidatesCount: Int?
}


// MARK: - Error Handling

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError:
            return "Failed to decode data"
        }
    }
}
