from pydantic import BaseModel, Field

from app.models.detalle_rutina import DetalleRutina


class DetalleRutinaCreate(BaseModel):
    ejercicio_id: int = Field(gt=0)
    repeticiones: int = Field(gt=0)
    series: int = Field(gt=0)
    sesiones_por_semana: int = Field(gt=0)
    peso: float = Field(ge=0)
    descanso_serie: str = Field(min_length=1, max_length=50)
    descanso_ejercicio: str = Field(min_length=1, max_length=50)
    rpe: int = Field(ge=1, le=10)


class DetalleRutinaUpdate(BaseModel):
    """Edición parcial de un detalle ya creado -todos los campos opcionales,
    solo se actualizan los que vengan presentes-. No incluye ejercicio_id:
    para cambiar el ejercicio se sigue eliminando y creando un detalle
    nuevo, eso no cambia con esta feature."""

    repeticiones: int | None = Field(default=None, gt=0)
    series: int | None = Field(default=None, gt=0)
    sesiones_por_semana: int | None = Field(default=None, gt=0)
    peso: float | None = Field(default=None, ge=0)
    descanso_serie: str | None = Field(default=None, min_length=1, max_length=50)
    descanso_ejercicio: str | None = Field(default=None, min_length=1, max_length=50)
    rpe: int | None = Field(default=None, ge=1, le=10)


class EnUsoResponse(BaseModel):
    """Shape genérico {"en_uso": bool} para los endpoints internos
    existe-ejercicio y existe-cliente -misma pregunta, distinto recurso-."""

    en_uso: bool


class DetalleRutinaResponse(BaseModel):
    detalle_id: int
    ejercicio_id: int
    repeticiones: int
    series: int
    sesiones_por_semana: int
    peso: float
    descanso_serie: str
    descanso_ejercicio: str
    rpe: int

    @classmethod
    def from_model(cls, detalle: DetalleRutina) -> "DetalleRutinaResponse":
        return cls(
            detalle_id=detalle.id,
            ejercicio_id=detalle.ejercicio_id,
            repeticiones=detalle.repeticiones,
            series=detalle.series,
            sesiones_por_semana=detalle.sesiones_por_semana,
            peso=detalle.peso,
            descanso_serie=detalle.descanso_serie,
            descanso_ejercicio=detalle.descanso_ejercicio,
            rpe=detalle.rpe,
        )
