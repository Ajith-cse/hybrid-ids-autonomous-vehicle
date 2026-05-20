from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List
import numpy as np
import joblib
import os
import random
from datetime import datetime, timezone
from pydantic import BaseModel, Field, ConfigDict

from dotenv import load_dotenv
load_dotenv()  # reads .env when running locally

# ── MongoDB ──────────────────────────────────
MONGO_URI = os.environ.get("MONGO_URI")
if not MONGO_URI:
    raise ValueError("MONGO_URI environment variable not set!")

try:
    from motor.motor_asyncio import AsyncIOMotorClient
    mongo_client = AsyncIOMotorClient(
        MONGO_URI,
        serverSelectionTimeoutMS=5000
    )
    db = mongo_client["av_ids"]
    logs_col = db["detection_logs"]
    MONGO_ENABLED = True
    print("[OK] MongoDB connected successfully")
except Exception as e:
    print(f"[ERROR] MongoDB connection failed: {e}")
    MONGO_ENABLED = False
    logs_col = None

# ── ML Models ────────────────────────────────
MODEL_DIR = os.path.join(os.path.dirname(__file__), "models")

def load_model(name):
    path = os.path.join(MODEL_DIR, name)
    if os.path.exists(path):
        return joblib.load(path)
    return None

rf_model  = load_model("random_forest.pkl")
iso_model = load_model("isolation_forest.pkl")
scaler    = load_model("scaler.pkl")

# In memory logs fallback
in_memory_logs: List[dict] = []

# ── FastAPI App ──────────────────────────────
app = FastAPI(
    title="AV Intrusion Detection API",
    description="Hybrid ML-based IDS for Autonomous Vehicles",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Schemas ──────────────────────────────────
class VehicleData(BaseModel):
    speed:        float = Field(..., ge=0,    le=300)
    rpm:          float = Field(..., ge=0,    le=9000)
    throttle:     float = Field(..., ge=0,    le=100)
    brake:        float = Field(..., ge=0,    le=100)
    steering:     float = Field(..., ge=-180, le=180)
    lat:          float = Field(..., ge=-90,  le=90)
    lon:          float = Field(..., ge=-180, le=180)
    can_freq:     float = Field(100.0)
    payload_size: float = Field(8.0)
    vehicle_id:   Optional[str] = "AV-001"

class PredictionResponse(BaseModel):

    model_config = ConfigDict(extra="ignore")
    vehicle_id:    str
    prediction:    str
    confidence:    float
    anomaly_score: float
    hybrid_label:  str
    timestamp:     str
    features:      dict

# ── WebSocket Manager ────────────────────────
class ConnectionManager:
    def __init__(self):
        self.active: List[WebSocket] = []

    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.active.append(ws)

    def disconnect(self, ws: WebSocket):
        self.active.remove(ws)

    async def broadcast(self, data: dict):
        for ws in self.active:
            try:
                await ws.send_json(data)
            except Exception:
                pass

manager = ConnectionManager()

# ── Prediction Logic ─────────────────────────
FEATURES = [
    "speed", "rpm", "throttle", "brake",
    "steering", "lat", "lon", "can_freq", "payload_size"
]

def predict(data: VehicleData) -> dict:
    x_raw = np.array([[
        data.speed, data.rpm, data.throttle,
        data.brake, data.steering, data.lat,
        data.lon, data.can_freq, data.payload_size
    ]])

    if scaler:
        x_scaled = scaler.transform(x_raw)
    else:
        x_scaled = x_raw

    rf_label      = 1
    rf_confidence = 0.5
    if rf_model:
        rf_label      = int(rf_model.predict(x_scaled)[0])
        rf_proba      = rf_model.predict_proba(x_scaled)[0]
        rf_confidence = float(rf_proba[rf_label])

    iso_raw   = -1
    iso_score = 0.0
    if iso_model:
        iso_raw   = iso_model.predict(x_scaled)[0]
        iso_score = float(-iso_model.score_samples(x_scaled)[0])

    iso_attack = iso_raw == -1
    rf_attack  = rf_label == 1

    if rf_attack and iso_attack:
        hybrid = "Attack"
    elif rf_attack:
        hybrid = "Attack"
    elif iso_attack and iso_score > 0.55:
        hybrid = "Attack"
    else:
        hybrid = "Normal"

    return {
        "prediction":    "Attack" if rf_attack else "Normal",
        "confidence":    round(rf_confidence * 100, 2),
        "anomaly_score": round(iso_score, 4),
        "hybrid_label":  hybrid,
    }

# ── Endpoints ────────────────────────────────
@app.get("/", tags=["Health"])
async def root():
    return {
        "status": "online",
        "service": "AV-IDS API",
        "version": "1.0.0"
    }

@app.get("/health", tags=["Health"])
async def health():
    return {
        "status": "ok",
        "rf_model":  rf_model is not None,
        "iso_model": iso_model is not None,
        "mongo":     MONGO_ENABLED,
    }

@app.post("/predict", response_model=PredictionResponse, tags=["ML"])
async def predict_endpoint(data: VehicleData):
    try:
        result = predict(data)
        ts = datetime.now(timezone.utc).isoformat()

        log = {
            "vehicle_id":    data.vehicle_id,
            "prediction":    result["prediction"],
            "confidence":    result["confidence"],
            "anomaly_score": result["anomaly_score"],
            "hybrid_label":  result["hybrid_label"],
            "timestamp":     ts,
            "features": {
                "speed":        data.speed,
                "rpm":          data.rpm,
                "throttle":     data.throttle,
                "brake":        data.brake,
                "steering":     data.steering,
                "lat":          data.lat,
                "lon":          data.lon,
                "can_freq":     data.can_freq,
                "payload_size": data.payload_size,
            }
        }

        if MONGO_ENABLED and logs_col is not None:
            inserted = await logs_col.insert_one(dict(log))
            log["id"] = str(inserted.inserted_id)
        else:
            log["id"] = str(len(in_memory_logs))
            in_memory_logs.append(log)
            if len(in_memory_logs) > 200:
                in_memory_logs.pop(0)

        await manager.broadcast(log)
        return PredictionResponse(**log)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/logs", response_model=List[dict], tags=["Logs"])
async def get_logs(limit: int = 50, vehicle_id: Optional[str] = None):
    try:
        if MONGO_ENABLED and logs_col is not None:
            query = {"vehicle_id": vehicle_id} if vehicle_id else {}
            cursor = logs_col.find(
                query, {"_id": 0}
            ).sort("timestamp", -1).limit(limit)
            logs = await cursor.to_list(length=limit)
        else:
            logs = list(reversed(in_memory_logs[-limit:]))
            if vehicle_id:
                logs = [l for l in logs if l.get("vehicle_id") == vehicle_id]
        return logs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/logs", tags=["Logs"])
async def clear_logs():
    global in_memory_logs
    if MONGO_ENABLED and logs_col is not None:
        await logs_col.delete_many({})
    else:
        in_memory_logs = []
    return {"message": "Logs cleared"}

@app.get("/simulate", tags=["Demo"])
async def simulate_data():
    is_attack = random.random() < 0.25
    if is_attack:
        return VehicleData(
            speed=random.uniform(150, 300),
            rpm=random.uniform(6000, 9000),
            throttle=random.uniform(80, 100),
            brake=random.uniform(0, 10),
            steering=random.uniform(-180, 180),
            lat=random.uniform(-90, 90),
            lon=random.uniform(-180, 180),
            can_freq=random.uniform(2000, 10000),
            payload_size=random.uniform(30, 64),
            vehicle_id="AV-001"
        ).model_dump()
    else:
        return VehicleData(
            speed=round(random.uniform(30, 100), 1),
            rpm=round(random.uniform(1500, 3500), 0),
            throttle=round(random.uniform(20, 60), 1),
            brake=round(random.uniform(5, 30), 1),
            steering=round(random.uniform(-30, 30), 1),
            lat=round(random.uniform(10.9, 11.1), 5),
            lon=round(random.uniform(76.9, 77.1), 5),
            can_freq=round(random.uniform(80, 120), 1),
            payload_size=round(random.uniform(6, 10), 1),
            vehicle_id="AV-001"
        ).model_dump()

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await manager.connect(ws)
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(ws)








        

