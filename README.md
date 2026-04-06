# 🚗 Hybrid ML-Based Intrusion Detection System for Autonomous Vehicles

A real-time mobile IDS app combining **RandomForest** (supervised) and **IsolationForest** (unsupervised anomaly detection) to detect CAN bus intrusions in autonomous vehicles.

---

## Architecture

```
┌─────────────────────────┐        REST / WebSocket       ┌──────────────────────┐
│   Flutter Mobile App    │ ◄────────────────────────────► │  FastAPI Backend     │
│                         │                                │                      │
│  ┌──────────────────┐   │   POST /predict                │  ┌────────────────┐  │
│  │ Dashboard Screen │   │   GET  /logs                   │  │ RandomForest   │  │
│  │  - Live metrics  │   │   GET  /simulate               │  │ IsolationForest│  │
│  │  - ML prediction │   │   WS   /ws                     │  │ StandardScaler │  │
│  │  - Alert banner  │   │                                │  └────────────────┘  │
│  └──────────────────┘   │                                │          │           │
│  ┌──────────────────┐   │                                │  ┌───────▼────────┐  │
│  │   Logs Screen    │   │                                │  │  MongoDB Atlas │  │
│  │  - History list  │   │                                │  │  detection_logs│  │
│  │  - Filter chips  │   │                                │  └────────────────┘  │
│  └──────────────────┘   │                                └──────────────────────┘
└─────────────────────────┘
```

## ML Pipeline

```
Vehicle Data (9 features)
        │
        ▼
  StandardScaler
        │
   ┌────┴────┐
   │         │
   ▼         ▼
RandomForest  IsolationForest
(supervised)  (unsupervised)
   │         │
   └────┬────┘
        │
   Hybrid Decision
   ┌────┴─────────────────────────────┐
   │  RF=Attack OR                    │
   │  (IF=Anomaly AND score > 0.55)   │  → "Attack"
   │  else                            │  → "Normal"
   └──────────────────────────────────┘
```

---

## Project Structure

```
av_ids/
├── ml/
│   ├── train_model.py          # Train RandomForest + IsolationForest
│   └── models/
│       ├── random_forest.pkl
│       ├── isolation_forest.pkl
│       └── scaler.pkl
│
├── backend/
│   ├── main.py                 # FastAPI app (all endpoints)
│   ├── requirements.txt
│   └── .env.example
│
├── flutter_app/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart           # Entry point + navigation
│       ├── models/
│       │   ├── vehicle_data_model.dart
│       │   ├── prediction_model.dart
│       │   └── log_model.dart
│       ├── services/
│       │   ├── api_service.dart    # Dio HTTP client
│       │   ├── ids_provider.dart   # State management
│       │   └── app_theme.dart      # Dark theme
│       ├── screens/
│       │   ├── dashboard_screen.dart
│       │   └── logs_screen.dart
│       └── widgets/
│           └── common_widgets.dart
│
├── start_backend.sh            # One-command backend startup
└── README.md
```

---

## Features

### ML Model
| Model | Type | Purpose |
|---|---|---|
| RandomForest (150 trees) | Supervised | Classifies known attack patterns |
| IsolationForest | Unsupervised | Detects novel anomalies |
| Hybrid Decision | Combined | Catches both known + zero-day attacks |

### Vehicle Features Used
| Feature | Description |
|---|---|
| speed | Vehicle speed (km/h) |
| rpm | Engine RPM |
| throttle | Throttle position (%) |
| brake | Brake pressure (%) |
| steering | Steering angle (°) |
| lat / lon | GPS coordinates |
| can_freq | CAN bus message frequency |
| payload_size | CAN frame payload (bytes) |

### API Endpoints
| Method | Endpoint | Description |
|---|---|---|
| GET | /health | Service health + model status |
| POST | /predict | Run hybrid ML prediction |
| GET | /logs | Fetch detection history |
| GET | /simulate | Generate demo vehicle data |
| DELETE | /logs | Clear all logs |
| WS | /ws | Real-time WebSocket stream |

---

## Setup

### 1. Train Models

```bash
cd ml/
pip install scikit-learn numpy pandas joblib
python train_model.py
```

### 2. Start Backend

```bash
# Configure MongoDB
cp backend/.env.example backend/.env
# Edit .env — set your MONGO_URI

# Start
bash start_backend.sh

# Or manually:
cd backend/
ln -s ../ml/models models
pip install -r requirements.txt
uvicorn main:app --reload
```

> API docs available at: http://localhost:8000/docs

### 3. Run Flutter App

```bash
cd flutter_app/
flutter pub get

# Android emulator (uses 10.0.2.2 for localhost)
flutter run

# Real device — update baseUrl in lib/services/api_service.dart
# Change: 'http://10.0.2.2:8000' → 'http://<your-machine-ip>:8000'
```

---

## MongoDB Atlas Setup

1. Create free cluster at [mongodb.com/atlas](https://mongodb.com/atlas)
2. Create database: `av_ids`, collection: `detection_logs`
3. Add your IP to the Network Access whitelist
4. Copy connection string to `backend/.env`

---

## Attack Types Detected

| Attack | Signature |
|---|---|
| Fuzzy Attack | Random/invalid CAN payloads |
| DoS Attack | High-frequency CAN flooding |
| Replay Attack | Repeated valid frames |
| Spoofing | Out-of-range sensor values |
| Zero-day | Isolated by IsolationForest |

---

## Tech Stack

- **Mobile**: Flutter 3.x + Provider + Dio
- **Backend**: Python 3.11 + FastAPI + Uvicorn
- **ML**: Scikit-learn (RandomForest + IsolationForest)
- **Database**: MongoDB Atlas (motor async driver)
- **Protocol**: REST + WebSocket

---

## License

MIT — built for research and educational purposes.


## Author
Ajith M
