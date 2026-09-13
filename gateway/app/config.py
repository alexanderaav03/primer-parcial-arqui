from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    JWT_SECRET: str = "cambiar-en-produccion"
    MS_EJERCICIOS_URL: str = "http://localhost:8001"
    MS_RUTINAS_URL: str = "http://localhost:8002"


settings = Settings()
