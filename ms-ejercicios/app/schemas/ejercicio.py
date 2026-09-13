from pydantic import BaseModel, Field


class EjercicioCreate(BaseModel):
    nombre: str = Field(min_length=1, max_length=255)
    descripcion: str = Field(min_length=1)
    imagen_url: str | None = Field(default=None, max_length=1024)
    video_url: str | None = Field(default=None, max_length=1024)

    # Valores de referencia sugeridos del banco - opcionales.
    repeticiones_sugeridas: int | None = Field(default=None, gt=0)
    series_sugeridas: int | None = Field(default=None, gt=0)
    peso_sugerido: float | None = Field(default=None, ge=0)
    descanso_serie_sugerido: str | None = Field(default=None, min_length=1, max_length=50)
    descanso_ejercicio_sugerido: str | None = Field(default=None, min_length=1, max_length=50)
    rpe_sugerido: int | None = Field(default=None, ge=1, le=10)


class EjercicioResponse(BaseModel):
    id: int
    nombre: str
    descripcion: str
    imagen_url: str | None
    video_url: str | None
    tiene_ejemplo_completo: bool

    repeticiones_sugeridas: int | None
    series_sugeridas: int | None
    peso_sugerido: float | None
    descanso_serie_sugerido: str | None
    descanso_ejercicio_sugerido: str | None
    rpe_sugerido: int | None

    model_config = {"from_attributes": True}
