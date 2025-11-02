import Foundation

final class AirportDirectory {
    static let shared = AirportDirectory()
    
    private(set) var codeToName: [String: String] = [:]
    
    private init() {
        loadAirportDatabase()
    }
    
    private func loadAirportDatabase() {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "csv") else {
            print("❌ Could not find airports.csv in bundle")
            return
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ Could not read airports.csv from bundle")
            return
        }

        print("✅ Loading airports.csv from bundle...")
        var loadedCount = 0

        for line in content.components(separatedBy: .newlines) {
            // OpenFlights CSV format: ID,"Name","City","Country","IATA","ICAO",lat,lon,...
            // e.g., 3577,"Seattle Tacoma International Airport","Seattle","United States","SEA","KSEA",...
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

        print("✅ Loaded \(loadedCount) airport codes")
        print("✅ Sample: KSEA = \(codeToName["KSEA"] ?? "NOT FOUND")")
    }
    
    /// Returns the airport name for a given code (IATA or ICAO), or the code itself if not found.
    static func name(for code: String?) -> String {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !code.isEmpty else { return "Unknown" }
        return shared.codeToName[code] ?? code
    }
}
