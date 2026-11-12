# Architecture Directive: Adaptive On-Device Processing & Hybrid Edge Engine

## 1. System Vision & Purpose
Transform the Flutter SPA into a **Local-First, Adaptive Edge Engine**. High-end devices (RAM > 4GB, multi-core CPUs) will perform mathematical and tactical computations ($xG$, $xA$, PPDA, Field Tilt) directly on-device using Dart Isolates. Low-end or memory-constrained devices will seamlessly fall back to lightweight compute endpoints provided by the FastAPI backend.

---

## 2. Decision Tree & Hardware Inspection Service

### Architecture Workflow:
```text
               [App Launch / Match Load]
                          │
          [DeviceCapabilityService.inspect()]
                          │
         ┌────────────────┴────────────────┐
         ▼                                 ▼
[High Tier: RAM > 4GB]           [Low Tier / Saver Mode]
         │                                 │
 [Mode: LocalIsolateCompute]      [Mode: CloudServerFallback]
         │                                 │
         ▼                                 ▼
Fetch Raw Events Payload         Fetch Pre-Computed Metrics
  `/api/v1/matches/raw`           `/api/v1/matches/computed`
         │                                 │
Execute Math in Background                 │
Dart Isolate (RAM cap <150MB)             │
         │                                 │
         └────────────────┬────────────────┘
                          ▼
                 [Render UI Components]
```

---

## 3. Core Implementation Blueprint

### A. Frontend Hardware Inspector (`frontend/lib/core/services/device_capability_service.dart`)
- Inspect system total RAM, available RAM, and CPU core counts via `device_info_plus`.
- Track battery state & thermal throttling.
- Expose a simple enum: `ComputeStrategy.localIsolate` or `ComputeStrategy.cloudFallback`.

### B. Background Isolate Engine (`frontend/lib/logic/engine/tactical_isolate_engine.dart`)
- Spawn a dedicated Dart Isolate using `Isolate.run()` to keep the UI Thread at 60/120 FPS.
- Compute $xG$ accumulators, PPDA index ($Passes_{defensive} / DefensiveActions$), and Field Tilt percentages.
- Enforce strict RAM caps: Dispose isolate memory immediately after computation.

### C. Backend API Bifurcation (`backend/app/api/v1/endpoints/matches.py`)
Provide two optimized endpoints:
1. `GET /api/v1/matches/{id}/raw` -> Ultra-light payload containing only raw event logs (for strong phones).
2. `GET /api/v1/matches/{id}/computed` -> Fully computed metrics payload (for legacy fallback).

---

## 4. OpenCode Execution Prompt Directives

YOU ARE ACTING AS A LEAD FLUTTER ARCHITECT AND HIGH-PERFORMANCE SYSTEMS ENGINEER.
EXECUTE THE FOLLOWING TASKS TO IMPLEMENT THE ADAPTIVE EDGE ENGINE:

1. CREATE `frontend/lib/core/services/device_capability_service.dart`:
   - Implement dynamic hardware check (RAM, Cores, Thermal state).
   - Provide a stream/provider for active `ComputeStrategy`.

2. CREATE `frontend/lib/logic/engine/tactical_isolate_engine.dart`:
   - Implement heavy math calculations ($xG$, $xA$, PPDA, Field Tilt) inside background Dart Isolates.
   - Add safe error fallback to cloud compute if isolate fails or times out (>500ms).

3. UPDATE `frontend/lib/logic/tactical_bloc.dart`:
   - Intercept incoming data requests based on `ComputeStrategy`.
   - Route high-end devices to raw data endpoints and local compute engine.
   - Route low-end devices directly to pre-computed backend endpoints.

4. UPDATE `backend/app/main.py` & ENDPOINTS:
   - Add `/raw` and `/computed` endpoints to allow client-side strategy choice.

EXECUTE THIS REFACTORING SYSTEMATICALLY, PRESERVING BLOC STATE INTEGRITY AND MINIMALIST UI REQUIREMENTS.