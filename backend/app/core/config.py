import os

class Settings:
    API_NAME: str = "AI for Science API"
    ENV: str = os.getenv("ENV", "local")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./app.db")
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/0")

settings = Settings()
