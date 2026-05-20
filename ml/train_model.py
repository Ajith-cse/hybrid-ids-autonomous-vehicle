"""
Hybrid ML Model Training: RandomForest + IsolationForest
For Autonomous Vehicle Intrusion Detection
"""
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier, IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import joblib
import os

# ─────────────────────────────────────────────
# 1. Synthetic Dataset Generation
# ─────────────────────────────────────────────
np.random.seed(42)
N = 5000

def generate_dataset():
    # Normal traffic
    normal = pd.DataFrame({
        "speed":        np.random.normal(60, 15, N),
        "rpm":          np.random.normal(2500, 400, N),
        "throttle":     np.random.normal(40, 10, N),
        "brake":        np.random.normal(20, 8, N),
        "steering":     np.random.normal(0, 15, N),
        "lat":          np.random.normal(11.0, 0.05, N),
        "lon":          np.random.normal(77.0, 0.05, N),
        "can_freq":     np.random.normal(100, 10, N),
        "payload_size": np.random.normal(8, 1, N),
        "label":        0
    })

    # Attack traffic (fuzzy/replay/DoS patterns)
    n_attack = N // 3
    attack = pd.DataFrame({
        "speed":        np.random.uniform(0, 200, n_attack),
        "rpm":          np.random.uniform(0, 8000, n_attack),
        "throttle":     np.random.uniform(0, 100, n_attack),
        "brake":        np.random.uniform(0, 100, n_attack),
        "steering":     np.random.uniform(-180, 180, n_attack),
        "lat":          np.random.uniform(-90, 90, n_attack),
        "lon":          np.random.uniform(-180, 180, n_attack),
        "can_freq":     np.random.uniform(500, 10000, n_attack),
        "payload_size": np.random.uniform(0, 64, n_attack),
        "label":        1
    })

    df = pd.concat([normal, attack], ignore_index=True).sample(frac=1, random_state=42)
    return df

# ─────────────────────────────────────────────
# 2. Train Models
# ─────────────────────────────────────────────
def train():
    print("Generating dataset...")
    df = generate_dataset()
    features = ["speed","rpm","throttle","brake","steering","lat","lon","can_freq","payload_size"]
    X = df[features].values
    y = df["label"].values

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Scaler
    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s  = scaler.transform(X_test)

    # RandomForest (supervised)
    print("Training RandomForest...")
    rf = RandomForestClassifier(n_estimators=150, max_depth=12, random_state=42, n_jobs=-1)
    rf.fit(X_train_s, y_train)
    y_pred = rf.predict(X_test_s)
    print("\n=== RandomForest Report ===")
    print(classification_report(y_test, y_pred, target_names=["Normal","Attack"]))

    # IsolationForest (unsupervised anomaly detection)
    print("Training IsolationForest...")
    normal_X = X_train_s[y_train == 0]
    iso = IsolationForest(n_estimators=100, contamination=0.1, random_state=42)
    iso.fit(normal_X)

    # Save artifacts
    os.makedirs("models", exist_ok=True)
    joblib.dump(rf,     "models/random_forest.pkl")
    joblib.dump(iso,    "models/isolation_forest.pkl")
    joblib.dump(scaler, "models/scaler.pkl")
    print("\n✅ Models saved to models/")

if __name__ == "__main__":
    train()






