# Smart Home Project (ESP32 • Firebase • Web App)

Live demos
- https://bash-smart-home-esp32.web.app/
- https://bash-smart-home-esp32.firebaseapp.com/

Table of contents
- Overview
- Key features
- Architecture
- Hardware & firmware
- Web application
- Firebase setup
- Security best practices
- Development — run locally
- Deployment
- Project layout
- Troubleshooting
- Contributing
- License & contact

Overview
This repository implements a complete end-to-end smart home prototype using ESP32 microcontrollers for edge devices, Firebase for cloud back-end services, and a web-based control panel hosted on Firebase Hosting. The project demonstrates how to collect sensor telemetry, synchronize device state in real time, and provide remote control via a responsive web UI.

Key features
- ESP32 firmware for Wi‑Fi connectivity, sensor reading, and actuator control
- Real‑time state synchronization using Firebase Realtime Database or Firestore
- Web control panel hosted on Firebase Hosting with live telemetry and device controls
- User access managed via Firebase Authentication
- Modular design: separate firmware and web application code so each can be extended independently

Architecture
1. ESP32 devices
   - Connect to local Wi‑Fi and Firebase
   - Publish telemetry (temperature, humidity, motion, light, etc.)
   - Subscribe to control topics/paths in Firebase to receive actuator commands (relays, LEDs, dimmers)
2. Firebase (backend)
   - Stores device state, telemetry, and user settings
   - Authentication provides user identity
   - Hosting serves the web UI
3. Web application
   - Connects to Firebase to display the current state and send commands
   - Provides dashboards, device lists, and historical data visualization (if enabled)

Supported hardware
- ESP32 family (ESP32 DevKitC and similar)
- Common sensors: DHT22/BME280 (temperature/humidity), PIR (motion), LDR (light)
- Actuators: relays, MOSFET drivers, PWM dimmers

Firmware
- The firmware component handles:
  - Wi‑Fi setup and reconnection logic
  - Firebase connectivity (REST or native client libraries)
  - Sensor sampling and debouncing
  - Command handling for actuators
  - OTA update hooks (optional — recommended for production)
- Typical files: firmware/ or esp32/ containing Arduino or PlatformIO projects
- Configuration: edit the sketch/config to add Wi‑Fi SSID, password, and Firebase settings (apiKey, projectId, databaseURL)

Web application
- Built with standard web technologies (HTML/CSS/JS) — may use a framework (React, Vue, or plain JS)
- Connects to Firebase for authentication and real‑time updates
- UI features:
  - Device list and status
  - Per‑device control panel (switches, sliders)
  - Live telemetry charts (optional)
  - User session management

Firebase setup (high level)
1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Realtime Database or Firestore depending on your preference
3. Configure database rules to limit access to authenticated users
4. Enable Firebase Authentication (email/password, Google, etc.)
5. Add web app credentials to the web app configuration
6. Optionally enable Hosting and deploy the web UI to the provided hosting domain (the live demos above show a deployed instance)

Security best practices
- Never commit API keys, service-account JSON files, or private credentials to source control.
- Use Firebase security rules to enforce per‑user access and validate incoming data shapes.
- Use Firebase Authentication to identify users and tie device ownership/permissions to user accounts.
- If you need server‑side privileged access, use a minimal backend or Cloud Functions with service account credentials stored securely.
- Consider using TLS and strong Wi‑Fi network protections for device communication.

Development — run locally
Prerequisites
- Node.js + npm (for web app)
- Arduino IDE or PlatformIO (for ESP32 firmware)
- Firebase CLI (optional, for deploying hosting)

Common steps
1. Clone repository:
   git clone https://github.com/AlajeBash/smart_home_project.git
   cd smart_home_project
2. Firmware:
   - Open firmware/ (or esp32/) in Arduino IDE or PlatformIO
   - Configure Wi‑Fi and Firebase settings in the sketch
   - Build and flash to your ESP32
3. Web app (example):
   cd web-app
   npm install
   Create a file or environment variables for Firebase config (apiKey, authDomain, projectId, databaseURL)
   npm start
4. Monitor device logs over serial and verify the device appears in the web UI

Deployment
- Web UI: build and deploy to Firebase Hosting
  npm run build
  firebase deploy --only hosting
- Firmware: flash ESP32 using Arduino IDE, PlatformIO, or esptool; implement OTA if desired

Repository layout (recommended / common)
- firmware/ or esp32/     — ESP32 firmware source code
- web-app/ or ui/         — Web application source code
- docs/                   — Architecture diagrams, wiring diagrams, and notes
- README.md               — This file

Troubleshooting
- Device won't connect to Wi‑Fi: verify SSID/password and check serial logs for IP assignment
- Firebase auth errors: confirm web app and firmware use correct project credentials and database URL
- Realtime updates not appearing: check database rules, security settings, and that your SDK connections are initialized correctly
- CORS or hosting issues: ensure Firebase hosting configuration and your web app origin match

Contributing
Contributions are welcome. Suggested workflow:
1. Open an issue to discuss the change
2. Create a feature branch (git checkout -b feature/your-change)
3. Make changes and include tests or documentation if applicable
4. Push and open a pull request with a clear description of changes

License
Include a LICENSE file in the repository to clarify terms. If you prefer MIT, Apache 2.0, or another license, add the file and a short note here.

Contact / Maintainer
Maintainer: AlajeBash
Repository: https://github.com/AlajeBash/smart_home_project

Acknowledgements
- Firebase — Realtime DB, Firestore, Authentication, Hosting
- ESP32 community libraries and examples
- Open source projects and tutorials that inspired this work

Notes
- This README is a general, production‑ready overview. If you want, I can add: sample wiring diagrams, example firmware code snippets, Firebase security rules examples, environment variable examples for the web app, or a CONTRIBUTING.md with PR templates.
- Live demos available at:
  - https://bash-smart-home-esp32.web.app/
  - https://bash-smart-home-esp32.firebaseapp.com/
