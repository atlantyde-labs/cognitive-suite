import os
import hashlib
from datetime import datetime

def get_analysis_signature(path):
    if not os.path.exists(path):
        return {
            "exists": False,
            "mtime": None,
            "hash": None,
            "human_time": None
        }

    try:
        with open(path, "rb") as f:
            content = f.read()
            file_hash = hashlib.sha256(content).hexdigest()

        mtime = os.path.getmtime(path)
        human_time = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")

        return {
            "exists": True,
            "mtime": mtime,
            "hash": file_hash,
            "human_time": human_time
        }

    except Exception:
        return {
            "exists": False,
            "mtime": None,
            "hash": None,
            "human_time": None
        }
