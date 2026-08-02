import json
import threading
import os
from pathlib import Path

_lock = threading.Lock()


def _data_path():
    env_path = os.getenv("RECOMMENDATION_SERVICE_DATA_PATH")
    if env_path:
        return Path(env_path)
    return Path(__file__).resolve().parents[1] / "data" / "destinations.json"


def read_data():
    path = _data_path()
    with _lock:
        if not path.exists():
            return {"destinations": [], "ratings": [], "comments": []}
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)


def write_data(data):
    path = _data_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with _lock:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
