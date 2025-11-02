import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var aircraftManager: AircraftManager

    @State private var tempServerAddress: String = ""
    @State private var showingResetAlert = false

    var body: some View {
        Form {
            Section {
                TextField("Server Address", text: $tempServerAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Text("Example: 192.168.1.100:8081 or http://myserver.com:8081")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Save & Reconnect") {
                    settings.serverAddress = tempServerAddress
                    aircraftManager.stopUpdating()
                    aircraftManager.startUpdating(serverURL: settings.baseURL)
                    dismiss()
                }
                .disabled(tempServerAddress.isEmpty)
            } header: {
                Text("Readsb Server")
            } footer: {
                Text("Enter the IP address and port of your readsb/tar1090 server")
            }

            Section {
                HStack {
                    Text("Current Server")
                    Spacer()
                    Text(settings.baseURL)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                HStack {
                    Text("Aircraft Tracked")
                    Spacer()
                    Text("\(aircraftManager.aircraft.count)")
                        .foregroundColor(.secondary)
                }

                if let lastUpdate = aircraftManager.lastUpdate {
                    HStack {
                        Text("Last Update")
                        Spacer()
                        Text(lastUpdate, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Status")
            }

            Section {
                Button("Reset to Default") {
                    showingResetAlert = true
                }
                .foregroundColor(.red)
            } header: {
                Text("Advanced")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About This App")
                        .font(.headline)

                    Text("ADS-B Radar displays real-time aircraft data from your readsb receiver with enhanced flight information from OpenSky Network.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    HStack {
                        Text("Data Sources:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Readsb (ADS-B data)")
                        Text("• OpenSky Network (Flight info)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                tempServerAddress = "192.168.100.197:8081"
                settings.serverAddress = tempServerAddress
                aircraftManager.stopUpdating()
                aircraftManager.startUpdating(serverURL: settings.baseURL)
            }
        } message: {
            Text("This will reset the server address to the default value.")
        }
        .onAppear {
            tempServerAddress = settings.serverAddress
        }
    }
}
