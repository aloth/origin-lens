# Origin Lens – Build Instructions

This directory contains the Flutter source code for Origin Lens. For an overview of features and to download the app, see the [main README](../README.md).

## Tech Stack

- **Framework:** Flutter 3.10+
- **Target:** iOS (primary), Android (planned)
- **C2PA Library:** [c2pa-rs](https://github.com/contentauth/c2pa-rs) v0.32
- **FFI Bridge:** [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/) 2.11.1
- **Design:** Material 3 with custom "Trust Blue" (#0066CC) theme

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                      │
│  (Dashboard, Analyze View, FAQ - Material 3 Design)     │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   C2PA Service (Dart)                    │
│     (analyzeFile, analyzeBytes, initialize)             │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Flutter Rust Bridge (FFI)                   │
│         (Generated bindings, type conversion)           │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                  Rust Native Library                     │
│    (c2pa-rs Reader API, manifest parsing, validation)   │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

```
origin-lens-code/
├── lib/
│   ├── main.dart                 # App entry point, RustLib initialization
│   ├── screens/
│   │   ├── dashboard_view.dart   # Home screen with app info
│   │   ├── analyze_view.dart     # Image analysis UI
│   │   └── faq_view.dart         # FAQ and help content
│   └── services/
│       └── c2pa_service.dart     # Dart interface to Rust C2PA library
├── rust_builder/
│   └── rust/
│       ├── Cargo.toml            # Rust dependencies (c2pa, flutter_rust_bridge)
│       └── src/
│           └── api/
│               └── c2pa_reader.rs # Native C2PA analysis implementation
└── ios/                          # iOS-specific configuration
```

## Building

### Prerequisites

- Flutter SDK 3.10.1+
- Rust toolchain (rustup)
- iOS Simulator or device
- Xcode 15+

### Setup

```bash
# Install Rust iOS targets
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

# Get Flutter dependencies
flutter pub get

# Generate Rust bridge bindings
flutter_rust_bridge_codegen generate

# Build for iOS simulator
flutter build ios --no-codesign --simulator

# Run on simulator
flutter run -d <device-id>
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests on the [GitHub repository](https://github.com/aloth/origin-lens).

## License

This project is licensed under the [GNU General Public License v3.0](../LICENSE).
