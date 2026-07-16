import json
import threading
from pathlib import Path

_lock = threading.Lock()
DATA_PATH = Path(__file__).resolve().parents[1] / "data" / "data.json"

def read_data():
    with _lock:
        with open(DATA_PATH, "r", encoding="utf-8") as f:
            return json.load(f)

def write_data(data):
    with _lock:
        with open(DATA_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
