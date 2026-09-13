from datetime import date

from pydantic import BaseModel, Field


class RutinaCreate(BaseModel):
    cliente_id: int = Field(gt=0)
    nombre: str = Field(min_length=1, max_length=255)
    fecha_inicio: date
    fecha_fin: date


class RutinaUpdate(BaseModel):
    nombre: str = Field(min_length=1, max_length=255)
    fecha_inicio: date
    fecha_fin: date


class RutinaResponse(BaseModel):
    id: int
    cliente_id: int
    nombre: str
    fecha_inicio: date
    fecha_fin: date

    model_config = {"from_attributes": True}
