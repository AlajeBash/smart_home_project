# Smart Home Front End 🏠

A cross-platform Flutter application for smart home automation that provides real-time monitoring and control of IoT devices. This app connects to ESP32 microcontrollers via Firebase Realtime Database to display sensor data and control home devices.

![Smart Home App](flutter_01.png)

## 🌟 Features

### 📊 Real-time Monitoring
- **Temperature Gauge**: Visual temperature display with color-coded ranges (0°C to 50°C)
- **Humidity Gauge**: Real-time humidity monitoring with percentage display
- **Live Data Updates**: Automatic synchronization with Firebase Realtime Database

### 🎛️ Device Control
- **Light Control**: Toggle lights on/off with real-time feedback
- **Smart Switches**: Remote control of connected devices via ESP32

### 📱 Responsive Design
- **Mobile-First**: Optimized mobile interface with card-based layout
- **Tablet Support**: Adaptive layout for larger screens
- **Desktop Ready**: Scalable design for desktop applications
- **Cross-Platform**: Runs on Android, iOS, Web, Windows, macOS, and Linux

### 🔥 Firebase Integration
- **Realtime Database**: Live synchronization of sensor data and device states
- **Cross-Platform Auth**: Secure authentication across all platforms
- **Cloud Connectivity**: Remote access from anywhere with internet connection

## 🏗️ Architecture

```
├── lib/
│   ├── main.dart                 # App entry point and Firebase initialization
│   ├── homepage.dart             # Main application wrapper
│   ├── exports.dart              # Centralized exports
│   ├── Responsive/               # Responsive design components
│   │   ├── mobile_body.dart      # Mobile-optimized UI
│   │   ├── tablet_body.dart      # Tablet layout
│   │   ├── desktop_body.dart     # Desktop interface
│   │   └── responsive_layout.dart # Layout switcher
│   ├── Widgets/                  # Reusable components
│   │   ├── Temperature/          # Temperature gauge widget
│   │   ├── Humidity/             # Humidity gauge widget
│   │   └── Devices/              # Device control widgets
│   ├── Network/                  # Firebase and networking services
│   └── firebase_options.dart     # Firebase configuration
```

## 🔧 Technologies Used

- **Flutter**: Cross-platform UI framework
- **Firebase Realtime Database**: Real-time data synchronization
- **Firebase Core**: Authentication and configuration
- **Syncfusion Flutter Gauges**: Professional gauge components
- **ESP32 Integration**: Hardware connectivity via Firebase

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.6.0+)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Firebase CLI](https://firebase.google.com/docs/cli) (for configuration)
- Code editor ([VS Code](https://code.visualstudio.com/), [Android Studio](https://developer.android.com/studio), etc.)

### Platform-specific requirements:
- **Android**: Android Studio, Android SDK
- **iOS**: Xcode (macOS only)
- **Web**: Chrome browser
- **Desktop**: Platform-specific build tools

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/AlajeBash/smart_home_front_end.git
cd smart_home_front_end
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Option A: Use Existing Configuration
The project is pre-configured with Firebase. The existing configuration connects to:
- **Project ID**: `bash-smart-home-esp32`
- **Database URL**: `https://bash-smart-home-esp32-default-rtdb.firebaseio.com`

#### Option B: Setup Your Own Firebase Project
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Realtime Database
3. Install Firebase CLI and login:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```
4. Configure Flutter for Firebase:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### 4. Database Structure
Your Firebase Realtime Database should have the following structure:
```json
{
  "sensors": {
    "temperature": 25.5,
    "humidity": 65.0
  },
  "home": {
    "light": true
  }
}
```

### 5. Run the Application

#### For Mobile (Android/iOS):
```bash
flutter run
```

#### For Web:
```bash
flutter run -d web
```

#### For Desktop:
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## 🛠️ Hardware Integration

This app is designed to work with ESP32 microcontrollers. Your ESP32 should:

1. **Connect to WiFi** and Firebase
2. **Read sensor data** (DHT22 for temperature/humidity)
3. **Control devices** (relays for lights)
4. **Update Firebase** with sensor readings
5. **Listen for commands** from the app

### Example ESP32 Code Structure:
```cpp
// Connect to WiFi and Firebase
// Read DHT22 sensor
// Update "sensors/temperature" and "sensors/humidity"
// Listen to "home/light" for relay control
```

## 📱 Usage

### Monitoring Sensors
- **Temperature**: Displayed in both gauge and text format
- **Humidity**: Real-time percentage with visual gauge
- **Auto-refresh**: Data updates automatically from Firebase

### Controlling Devices
- **Light Switch**: Toggle the main light on/off
- **Real-time Feedback**: Switch state reflects actual device status
- **Remote Control**: Control from anywhere with internet access

### Responsive Interface
- **Mobile**: Card-based layout with optimized spacing
- **Tablet**: Expanded layout with better spacing
- **Desktop**: Full-width interface with enhanced controls

## 🔧 Development

### Project Structure
- **`lib/exports.dart`**: Central export file for clean imports
- **`lib/Responsive/`**: Responsive design implementation
- **`lib/Widgets/`**: Reusable UI components
- **`lib/Network/`**: Firebase service layer

### Key Components
- **`NetworkService`**: Handles all Firebase interactions
- **`TemperatureGauge`**: Syncfusion-based temperature visualization
- **`HumidityGauge`**: Real-time humidity display
- **`ResponsiveLayout`**: Adaptive layout management

### Development Commands
```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Build for production
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is open source. Feel free to use and modify as needed for your smart home projects.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Firebase](https://firebase.google.com/) - Backend services
- [Syncfusion](https://www.syncfusion.com/flutter-widgets) - Gauge components
- [ESP32](https://www.espressif.com/en/products/socs/esp32) - Hardware platform

## 📞 Support

If you have any questions or need help:
- Open an [issue](https://github.com/AlajeBash/smart_home_front_end/issues)
- Check the [Flutter documentation](https://flutter.dev/docs)
- Review [Firebase documentation](https://firebase.google.com/docs)

---

Built with ❤️ using Flutter and Firebase
