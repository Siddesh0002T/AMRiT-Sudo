# 🚀 BlueMesh Prototype Release v1.0.0

Welcome to the **BlueMesh & BlueBand v1.0.0** prototype build release!

This release introduces the complete dual-app Bluetooth Low Energy (BLE) smart mesh attendance and real-time monitoring infrastructure.

---

## 📱 Prototype Application Downloads

| Application | Role | Version | Download Link | SHA-256 Checksum |
|---|---|---|---|---|
| **BlueMesh Staff** | Faculty Host & Mesh Visualizer | `v1.0.0+1` | [BlueMesh-Staff-v1.0.0.apk](./BlueMesh-Staff-v1.0.0.apk) | `cf21b9e5f9552b06e8daba2d0d55cd754a3399b9a15c5da44d487618064b75a8` |
| **BlueBand Student** | Student Node & Biometric Identity | `v1.0.0+1` | [BlueBand-Student-v1.0.0.apk](./BlueBand-Student-v1.0.0.apk) | `8d4b4570a9dcee4a540dfbb69738d1950e387b7eb4d6cf122d87c944bb122b10` |

---

## ✨ Release Highlights

### 1. Minimalist Light-Theme App Icons
- **BlueMesh Staff**: Bold, geometric mesh network crest with royal blue & electric cyan gradient on pure crisp white squircle.
- **BlueBand Student**: Circular smart wristband emblem with dynamic biometric pulse waveform and Bluetooth connectivity glyph on pure crisp white squircle.
- High-resolution adaptive launcher assets bundled across `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`, iOS, Web, and desktop.

### 2. BlueMesh (Staff Host App)
- **Session Host Engine**: Starts BLE advertising & GATT service (`0000AAA1-...`) to orchestrate mesh nodes.
- **Real-time Mesh Topology Visualizer**: Dynamic animated graph displaying student nodes, signal strengths (RSSI), packet counts, and hop states.
- **Automated Attendance Roster**: Automatic verification, live duration tracking, and percentage calculation.
- **Analytics & Export**: Session history log, detailed student attendance breakdown, and one-tap CSV export.

### 3. BlueBand (Student Client App)
- **Local Biometric Fingerprint Authentication**: Secure student identity verification with hardware biometrics.
- **BLE Mesh Packet Dispatcher**: Periodic encrypted heartbeat broadcasts and attendance packets.
- **Status LED & Packet Inspector**: Real-time visual feedback for scanning, connecting, and verified states.
- **Custom Identity Configuration**: Setup student Roll Number, Name, and Section.

---

## 📲 How to Install & Test the Prototype

1. Download the `.apk` file directly to your Android device (Android 7.0 / SDK 24+ recommended).
2. Open the downloaded APK and tap **Install** (allow *Install unknown apps* if prompted by your browser/file manager).
3. Open the app and grant **Bluetooth** and **Nearby Devices / Location** permissions.
4. Launch **BlueMesh Staff** on one device and start an attendance session.
5. Launch **BlueBand Student** on another device (or multiple devices), verify fingerprint, and watch the node connect instantly on the host mesh network map!
