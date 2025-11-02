import Foundation

final class AircraftTypeDirectory {
    static let shared = AircraftTypeDirectory()

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

        // Short/generic codes (when specific variant unknown)
        codeToName["A3"] = "Airbus A330"
        codeToName["A5"] = "Airbus A350"
        codeToName["A350"] = "Airbus A350"
        codeToName["A380"] = "Airbus A380"
        codeToName["A330"] = "Airbus A330"
        codeToName["B77"] = "Boeing 777"
        codeToName["B78"] = "Boeing 787"
        codeToName["B73"] = "Boeing 737"
        codeToName["B74"] = "Boeing 747"
        codeToName["B75"] = "Boeing 757"
        codeToName["B76"] = "Boeing 767"

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