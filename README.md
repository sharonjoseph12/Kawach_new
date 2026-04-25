<p align="center">
  <img src="https://img.shields.io/badge/🛡️_KAWACH-AI_Powered_Safety-C2185B?style=for-the-badge&labelColor=880E4F" alt="Kawach Badge"/>
  <br/>
  <strong>Your AI-Powered Personal Safety Shield</strong>
  <br/>
  <em>Built for Bangalore 2026 — Women's Safety, Reimagined</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Supabase-Realtime-3ECF8E?logo=supabase&logoColor=white" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Gemini_AI-Powered-4285F4?logo=google&logoColor=white" alt="Gemini"/>
  <img src="https://img.shields.io/badge/BLE_Mesh-Offline_Ready-7C4DFF" alt="BLE Mesh"/>
</p>

---

## 🚨 The Problem

> **Every 4 minutes**, a crime against women is reported in India. Existing safety apps fail because they require **unlocking the phone**, **opening the app**, and **pressing a button** — none of which are possible when you're being followed, restrained, or in shock.

## 💡 The Solution

**Kawach** is a multi-layered safety system that works **even when you can't touch your phone**:

- 🗣️ **Say "Help me"** → Voice-activated SOS via wake word detection
- 📱 **Press volume button 3×** → Pocket-triggered SOS via native hardware interception
- 🤖 **AI detects anomaly** → Behavioral pattern analysis triggers automatic alert
- 🔋 **Battery hits critical** → Dead-battery SOS fires before phone dies
- 📡 **No internet?** → BLE mesh relays your SOS to nearby Kawach users

---

## ✨ Feature Overview

| Feature | Description | How It Works |
|---------|-------------|--------------|
| 🔴 **SOS Button** | Hold 2s to trigger emergency | Long-press with haptic feedback + progress ring |
| 📱 **Volume Button SOS** | 3× volume-down in 2s | Native Kotlin `KeyEvent` interception |
| 🗣️ **Wake Word SOS** | Say "Help me" hands-free | On-device speech recognition → SOS trigger |
| 🤝 **Shake Detection** | Shake phone vigorously | Accelerometer pattern matching |
| 📡 **BLE Mesh Relay** | Offline SOS broadcast | Google Nearby Connections P2P mesh |
| 📞 **Cellular SMS Fallback** | SMS when no internet | Native `SmsManager` bypass |
| 🤖 **Guardian AI Chat** | 24/7 AI safety assistant | Gemini Pro with streaming + spatial context |
| 📹 **Evidence Vault** | Auto-capture photos/audio | SHA-256 hashed, encrypted, tamper-proof |
| 🚶 **Safe Walk** | Timed journey monitoring | Route deviance detection + auto-SOS |
| 📞 **Fake Call** | Simulate incoming call | Full-screen caller UI to deter attackers |
| 🔇 **Stealth Mode** | Black screen during SOS | Screen goes dark, SOS continues silently |
| 🔐 **Duress PIN** | Fake-cancel under coercion | Reversed PIN secretly escalates to high-priority |
| 🎭 **App Disguise** | Hides as Calculator app | Android component toggling via `PackageManager` |
| 🔊 **Panic Siren** | Max-volume alarm | Looping siren with haptic feedback |
| 🗺️ **Safety Heat Map** | Visualize risky areas | Community incident data overlay |
| 🏥 **System Diagnostics** | 10-point health check | GPS, BLE, battery, network, permissions |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                    PRESENTATION                      │
│  Flutter UI (BLoC) → Pages → Widgets                │
├─────────────────────────────────────────────────────┤
│                    DOMAIN                            │
│  SOS Pipeline → Safety Score → Evidence Capture     │
├─────────────────────────────────────────────────────┤
│                    DATA LAYER                        │
│  Supabase Realtime │ Isar Local DB │ Secure Storage │
├─────────────────────────────────────────────────────┤
│              NATIVE BRIDGE (Kotlin)                  │
│  Volume Keys │ SMS │ BLE Mesh │ App Disguise        │
├─────────────────────────────────────────────────────┤
│            BACKGROUND SERVICES                       │
│  Location Tracking │ AI Monitoring │ Wake Word       │
│  Evidence Upload │ Battery Monitor │ Mesh Relay      │
└─────────────────────────────────────────────────────┘
```

---

## 🔴 How the SOS Pipeline Works

```
1. TRIGGER          2. EVIDENCE           3. ALERT              4. TRACK
───────────         ──────────            ──────────            ──────────
• Manual hold       • Front-cam burst     • Supabase realtime   • GPS every 5s
• Volume 3×         • Audio recording     • Push notification   • Live location
• Wake word         • GPS snapshot        • Cellular SMS        • BLE mesh relay
• Shake detect      • SHA-256 hash        • BLE mesh broadcast  • Battery monitor
• AI anomaly        • Encrypted upload    • Guardian live grid   • Stealth mode
• Route deviance                                                
• Dead battery                                                  
```

**7 trigger methods → Auto evidence capture → Multi-channel alert → Continuous tracking**

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.x + Material 3 | Cross-platform UI with dark mode |
| **State** | flutter_bloc + HydratedBloc | Persistent state across app restarts |
| **Backend** | Supabase (Postgres + Realtime) | Auth, DB, realtime subscriptions |
| **AI** | Google Gemini Pro | Guardian AI chat with action detection |
| **ML** | TensorFlow Lite | On-device behavioral anomaly detection |
| **Bluetooth** | Nearby Connections + BLE | Offline mesh SOS relay |
| **Native** | Kotlin (Android) | Volume keys, SMS, app disguise |
| **Security** | AES + SHA-256 + Secure Storage | Evidence integrity + encrypted PINs |
| **Monitoring** | Sentry + Talker | Error tracking + structured logging |
| **DI** | GetIt + Injectable | Service locator pattern |

---

## 🏃 Quick Start

```bash
# Clone and install
git clone https://github.com/your-team/kawach.git
cd kawach
flutter pub get

# Set up environment
cp .env.example .env
# Fill in Supabase URL, Anon Key, Gemini API Key

# Run
flutter run
```

### Prerequisites
- Flutter 3.x SDK
- Android Studio / VS Code
- A physical Android device (BLE mesh + volume button features need real hardware)
- Supabase project with the schema from `supabase_migration.sql`

---

## 🎯 For Judges: Demo Walkthrough

1. **Launch** → Watch the animated splash screen
2. **Onboarding** → Grant permissions, set 4-digit PIN
3. **Home Screen** → See live safety score + active protection status
4. **SOS Button** → Hold 2s to trigger (vibration + evidence capture starts)
5. **SOS Active** → See live GPS, evidence count, guardian notification grid
6. **Stealth Mode** → Tap STEALTH button (screen goes black, SOS continues)
7. **Guardian AI** → Chat with Gemini — say "I feel unsafe" for AI-triggered SOS
8. **Fake Call** → Tap to receive a simulated incoming call from "Police Control Room"
9. **Safe Walk** → Set a timer for your journey, PIN required to cancel
10. **System Diagnostics** → 10-point health check of all protection systems
11. **Settings** → Toggle AI features, mesh relay, app disguise (Calculator mode)

---

## 👥 Team

Built with ❤️ for the **Build for Bangalore 2026** Hackathon.

---

<p align="center">
  <em>"Safety isn't a feature — it's a promise."</em>
  <br/>
  <strong>🛡️ KAWACH</strong>
</p>
