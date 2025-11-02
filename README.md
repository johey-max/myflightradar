# ✈️ FlightRadar

A real-time aircraft tracking iOS app that visualizes ADS-B data from your local receiver with live flight information enrichment from OpenSky Network.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-Private-red.svg)

## 🌟 Features

### Real-Time Tracking
- **Live Aircraft Updates** - Positions update every 2 seconds from your ADS-B receiver
- **Interactive Map** - Aircraft icons rotate to show direction of travel
- **Flight Trails** - Visual history of aircraft paths with altitude-based coloring
- **Auto-Refresh** - Seamless updates on both iPhone and iPad

### Rich Information Display
- **Aircraft Details** - Type, callsign, altitude, speed, heading, and squawk
- **Airport Names** - Full airport names for departure and destination (OpenFlights database)
- **Aircraft Types** - 120+ aircraft type mappings (Boeing, Airbus, Embraer, etc.)
- **Flight Photos** - Aircraft images from Planespotters.net
- **Route Information** - Origin and destination from OpenSky Network

### Analytics & Statistics
- **Lifetime Statistics** - Persistent tracking across app restarts
- **Aircraft Type Distribution** - See most common aircraft in your area
- **Altitude Distribution** - Breakdown by flight level
- **Coverage Heatmap** - Visualize your receiver's range with RSSI data
- **Max Range Tracking** - Monitor your antenna's performance

### Home Screen Widget
- **Live Map Widget** - Real Apple Maps with aircraft positions
- **Multiple Sizes** - Small, Medium, and Large widget support
- **Auto-Updates** - Refreshes every 60 seconds
- **Aircraft Count** - See active aircraft at a glance

### Universal App
- **iPhone & iPad** - Adaptive layouts for all devices
- **Split View on iPad** - Sidebar navigation with detail pane
- **Portrait & Landscape** - Full orientation support
- **Dark Mode** - Automatic theme support

## 📱 Screenshots

*Coming soon - add your screenshots here!*

## 🔧 Requirements

- **iOS/iPadOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**
- **ADS-B Receiver** running readsb/tar1090 (e.g., RTL-SDR Blog V4)
- **OpenSky Network Account** (free) for flight information enrichment
- **Network Access** to your ADS-B receiver (local or via Tailscale)

## 📥 Installation

1. Clone the repository:
```bash
git clone https://github.com/johey-max/myflightradar.git
cd myflightradar
```

2. Open in Xcode:
```bash
open FlightRadar.xcodeproj
```

3. Update bundle identifiers if needed:
   - Main app: `com.joge.FlightRadar`
   - Widget: `com.joge.FlightRadar.FlightRadarWidget`

4. Build and run (⌘R)

## ⚙️ Configuration

### ADS-B Receiver Setup

1. Ensure your receiver is running readsb/tar1090
2. Note your receiver's IP address and port (default: `8081`)
3. If remote access needed, set up Tailscale VPN

### OpenSky Network API

1. Create a free account at [OpenSky Network](https://opensky-network.org/)
2. Generate OAuth2 credentials in your account settings
3. Update `AppSettings.swift` with your credentials:
```swift
let openSkyClientId = "your-client-id"
let openSkyClientSecret = "your-client-secret"
```

### Receiver Location

Update your receiver's coordinates in `AircraftManager.swift`:
```swift
let receiverLocation = CLLocation(latitude: YOUR_LAT, longitude: YOUR_LON)
```

## 🚀 Usage

1. **Launch the app** - It will connect to your receiver automatically
2. **Map Tab** - View aircraft in real-time with trails
3. **List Tab** - Browse all detected aircraft
4. **Stats Tab** - See lifetime statistics and distributions
5. **Coverage Tab** - Visualize your receiver's range
6. **Add Widget** - Long-press home screen → Add FlightRadar widget

### First Time Setup

Tap the gear icon to configure:
- Server address (e.g., `192.168.1.100:8081` or `100.87.34.53:8081` for Tailscale)
- Enable/disable local vs remote server

## 🏗️ Architecture

### Tech Stack
- **SwiftUI** - Modern declarative UI framework
- **MapKit** - Native iOS maps with iOS 17+ APIs
- **WidgetKit** - Home screen widget implementation
- **Combine** - Reactive data flow
- **App Groups** - Data sharing between app and widget

### Key Components
- `AircraftManager` - Central state management and data fetching
- `NetworkService` - API communication with OAuth2 token management
- `AircraftTypeDirectory` - 120+ aircraft type mappings
- `AirportDirectory` - Full airport names from OpenFlights database
- `FlightStatistics` - Persistent lifetime statistics

### Optimizations
- **Debounced Saves** - Statistics save every 10s (not every change)
- **API Throttling** - Max 1 flight info request per aircraft per 60s
- **Memory Cleanup** - Automatic cleanup every ~100 seconds
- **Batch Updates** - Coverage points collected in batches
- **Widget Efficiency** - 60-second refresh interval

## 📊 Data Sources

- **ADS-B Data** - Your local readsb/tar1090 receiver
- **Flight Information** - [OpenSky Network API](https://opensky-network.org/)
- **Aircraft Photos** - [Planespotters.net](https://www.planespotters.net/)
- **Airport Database** - [OpenFlights](https://openflights.org/)

## 🎨 Features Highlights

- **Smart Type Detection** - Filters out "Unknown" aircraft from statistics
- **Automatic Airport Fetching** - Flight info loads 2s after aircraft appears
- **Persistent Statistics** - Lifetime tracking survives app restarts
- **Rotating Icons** - Plane icons point in actual direction of travel
- **Gray Range Rings** - 50km interval rings on coverage map
- **Background/Foreground** - Pauses updates when backgrounded to save battery

## 📝 License

Copyright © 2025 Joseph Langstroth. All Rights Reserved.

This is proprietary software. Unauthorized copying, distribution, or modification is prohibited.

## 🙏 Acknowledgments

- Built with [Claude Code](https://claude.com/claude-code)
- Airport data from [OpenFlights](https://openflights.org/)
- Flight data from [OpenSky Network](https://opensky-network.org/)
- Aircraft photos from [Planespotters.net](https://www.planespotters.net/)

## 🐛 Known Issues

- Console warnings about PerfPowerTelemetry are harmless iOS simulator noise
- Widget may show cached data briefly after app restart

## 🔮 Future Enhancements

- [ ] Flight path predictions
- [ ] Push notifications for specific aircraft
- [ ] Export statistics to CSV
- [ ] Multi-receiver support
- [ ] Aircraft filtering by type/altitude
- [ ] Custom alert zones

---

**Made with ❤️ for aviation enthusiasts**
