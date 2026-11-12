# Master Specification: On-Device Next-Gen Adaptive Capabilities & Modular International Engine

## 1. Core Engineering Principles
1. **Zero-Server-Bloat Guarantee:** All heavy computations, ML inferences, audio processing, and voice recognition execute 100% locally on the device (On-Device Local Processing). The server remains purely a minimal raw event data pipe.
2. **On-Demand Dynamic Packaging (Lazy-Loaded Confederations):** International breaks and confederation tournaments (UEFA, CAF, CONMEBOL, AFC, CONCACAF, OFC) are treated as optional micro-modules downloaded only when activated by the user.

---

## 2. On-Device Adaptive Intelligence Suite (100% Local Execution)

### A. Local Audio Sync Engine (TV Delay Matcher)
* **Purpose:** Synchronize app match clock and tactical alerts with live TV broadcast delay.
* **Mechanism:**
  * Uses local microphone for 2-3 seconds to compute an audio fingerprint using local FFT / Cross-Correlation algorithms.
  * Measures latency offset $\Delta t$ (e.g., TV is 14 seconds behind live feed).
  * Automatically shifts local event timers and notifications by $+\Delta t$ locally.
  * **Privacy & Efficiency:** Audio data never leaves RAM or device memory; zero network calls to backend.

### B. Adaptive Tactical Shift Detector
* **Purpose:** Detect tactical changes in real-time (e.g., switching to Low Block, high pressing fatigue).
* **Mechanism:**
  * Evaluates sliding 5-minute windows of $PPDA$ and $Field\ Tilt$ on local isolates.
  * Triggers smart tactical banners (e.g., *"Tactical Shift: Team A dropped possession by 35% since Min 60"*).

### C. Local Goal Threat Index (ONNX Runtime / TFLite Edge AI)
* **Purpose:** Real-time goal threat prediction based on spatial shot density and final-third entries.
* **Mechanism:**
  * Executes a quantized ONNX model (`goal_threat_v1.onnx`, size < 2MB) locally on device NPU/GPU.
  * Renders real-time momentum spikes on UI without cloud processing latency.

### D. Hands-Free Voice Query Engine for Commentators
* **Purpose:** Voice queries for commentators during live commentary without touching screen.
* **Mechanism:**
  * Integrates lightweight local Speech-to-Text (e.g., Whisper-Tiny / ONNX Engine).
  * Answers voice commands like *"xG summary"* or *"Show PPDA"* directly on UI.

### E. BLE Mesh Peer-to-Peer Relay (Stadium Offline Mode)
* **Purpose:** Stadium connectivity resilience during mobile network congestion.
* **Mechanism:**
  * Uses Bluetooth Low Energy (BLE Mesh) to relay raw match text bytes from connected devices to adjacent devices offline.

---

## 3. Modular Confederation Engine (Dynamic Lazy Loading)

### A. Confederation Micro-Modules Architecture

```
[App Core Payload] ─── (Default: 3 Core + 1 Geo-IP + 1 Selected)
         │
         ├── [Module: UEFA (Europe) - Optional On-Demand]
         ├── [Module: CAF (Africa) - Optional On-Demand]
         ├── [Module: CONMEBOL (South America) - Optional On-Demand]
         ├── [Module: AFC (Asia) - Optional On-Demand]
         ├── [Module: CONCACAF (North/Central America) - Optional On-Demand]
         └── [Module: OFC (Oceania) - Optional On-Demand]
```

### B. Confederation On-Demand Strategy
* **Zero Overhead by Default:** Unselected confederations are completely ignored in background fetch pipelines and storage.
* **On-Demand Activation:** When a user toggles a confederation (e.g., Africa / CAF or Europe / UEFA):
  1. App fetches the specific fixture metadata for international windows.
  2. Stores module data locally in isolated Hive boxes (`caf_fixtures`, `uefa_fixtures`).
  3. Deletion/Unsubscribe: Toggling off a confederation purges local cache instantly.

---

## 4. Technical File Structure Additions

```
frontend/lib/
├── core/
│   ├── modules/
│   │   ├── confederation_module_manager.dart
│   │   └── models/confederation_enum.dart
│   └── services/
│       ├── audio_sync_service.dart
│       ├── voice_query_service.dart
│       └── ble_mesh_relay.dart
├── logic/
│   ├── engine/
│   │   ├── tactical_shift_detector.dart
│   │   └── goal_threat_onnx_engine.dart
│   └── bloc/
│       └── confederations_bloc.dart
```

---

## 5. System Execution Prompts for OpenCode

```text
YOU ARE ACTING AS A PRINCIPAL MOBILE SYSTEMS ARCHITECT AND ON-DEVICE AI SPECIALIST.
EXECUTE THE FOLLOWING SYSTEM MODIFICATIONS BASED ON NEXT_GEN_TACTICAL_SPEC.MD:

1. IMPLEMENT ON-DEMAND CONFEDERATION MODULES (`confederation_module_manager.dart`):
   - Support lazy-loaded international break data by confederation (UEFA, CAF, CONMEBOL, AFC, CONCACAF, OFC).
   - Ensure users can toggle confederation modules on/off without fetching unneeded global data.
   - Store active confederation modules in Hive local storage.

2. IMPLEMENT ON-DEVICE TACTICAL SHIFT DETECTOR (`tactical_shift_detector.dart`):
   - Run rolling 5-minute computations of PPDA and Field Tilt in a local Dart Isolate.
   - Emit tactical alerts when metric thresholds shift by >25% in a match phase.

3. IMPLEMENT LOCAL AUDIO SYNC STUB (`audio_sync_service.dart`):
   - Calculate latency offset between broadcast audio and live timer locally.
   - Adjust local match ticker offset dynamically.

4. IMPLEMENT CONFEDERATION FILTER CHIPS IN UI:
   - Add an optional "International Window / Confederations" configuration drawer in the SPA layout.
   - Allow users to download/enable only preferred regions (e.g., Europe + Africa).

MAINTAIN STRICT ZERO-NEWS RULE, MINIMALIST UI, AND LOCAL-FIRST PERFORMANCE CONSTRAINTS AT ALL TIMES.
```