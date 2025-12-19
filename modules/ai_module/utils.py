"""
UWP AI Utilities
"""

import hashlib
import json
import pickle
from datetime import datetime
from pathlib import Path

def get_cache_dir():
    """Get cache directory"""
    cache_dir = Path.home() / ".universal-workspace" / "cache" / "ai"
    cache_dir.mkdir(parents=True, exist_ok=True)
    return cache_dir

def cache_result(key, data, ttl=3600):
    """Cache data with TTL"""
    cache_dir = get_cache_dir()
    key_hash = hashlib.md5(key.encode()).hexdigest()
    cache_file = cache_dir / f"{key_hash}.cache"
    
    cache_data = {
        "timestamp": datetime.now().isoformat(),
        "ttl": ttl,
        "data": data
    }
    
    with open(cache_file, 'wb') as f:
        pickle.dump(cache_data, f)

def get_cached_result(key):
    """Get cached data if not expired"""
    cache_dir = get_cache_dir()
    key_hash = hashlib.md5(key.encode()).hexdigest()
    cache_file = cache_dir / f"{key_hash}.cache"
    
    if cache_file.exists():
        with open(cache_file, 'rb') as f:
            cache_data = pickle.load(f)
        
        cache_time = datetime.fromisoformat(cache_data["timestamp"])
        if (datetime.now() - cache_time).seconds < cache_data["ttl"]:
            return cache_data["data"]
    
    return None

def log_activity(module, action, details=None):
    """Log AI activity"""
    log_dir = Path.home() / ".universal-workspace" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    
    log_file = log_dir / "ai_activity.log"
    
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "module": module,
        "action": action,
        "details": details
    }
    
    with open(log_file, 'a') as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")

def validate_config(config):
    """Validate AI configuration"""
    required_fields = ["model", "language", "max_tokens"]
    
    for field in required_fields:
        if field not in config:
            return False, f"Chybí povinné pole: {field}"
    
    if config["max_tokens"] < 1 or config["max_tokens"] > 10000:
        return False, "max_tokens musí být mezi 1 a 10000"
    
    return True, "Konfigurace je validní"
