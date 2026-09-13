from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    DATABASE_URL: str = "postgresql://user:password@localhost:5432/ejercicios"
    JWT_SECRET: str = "cambiar-en-produccion"
    JWT_EXPIRE_MINUTES: int = 60
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_BUCKET: str = "ejercicios-media"
    MS_RUTINAS_URL: str = "http://localhost:8002"


settings = Settings()
