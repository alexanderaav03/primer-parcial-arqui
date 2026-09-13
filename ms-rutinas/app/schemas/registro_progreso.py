from datetime import datetime

from pydantic import BaseModel, Field


class RegistroProgresoCreate(BaseModel):
    series_realizadas: int = Field(gt=0)
    repeticiones_realizadas: int = Field(gt=0)
    peso_realizado: float = Field(ge=0)
    nota: str | None = Field(default=None, max_length=500)


class RegistroProgresoResponse(BaseModel):
    id: int
    detalle_rutina_id: int
    fecha: datetime
    series_realizadas: int
    repeticiones_realizadas: int
    peso_realizado: float
    nota: str | None

    model_config = {"from_attributes": True}
