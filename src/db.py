# src/db.py
import yaml
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

def load_config():
    with open("config/config.yaml", "r") as f:
        return yaml.safe_load(f)

_cfg = load_config()["db"]
DATABASE_URL = (
    f"postgresql://{_cfg['user']}:{_cfg['password']}@{_cfg['host']}:"
    f"{_cfg['port']}/{_cfg['database']}"
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
