from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.detalle_rutina import DetalleRutina
from app.models.registro_progreso import RegistroProgreso


class RegistroProgresoRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_by_detalle(self, detalle_rutina_id: int) -> list[RegistroProgreso]:
        stmt = (
            select(RegistroProgreso)
            .where(RegistroProgreso.detalle_rutina_id == detalle_rutina_id)
            .order_by(RegistroProgreso.fecha.desc())
        )
        return list(self.db.scalars(stmt).all())

    def create(self, registro: RegistroProgreso) -> RegistroProgreso:
        self.db.add(registro)
        self.db.commit()
        self.db.refresh(registro)
        return registro

    def exists_by_rutina(self, rutina_id: int) -> bool:
        """True si algún DetalleRutina de esta rutina tiene al menos 1
        RegistroProgreso -se consulta local, ambas tablas viven en esta
        misma base-."""
        stmt = (
            select(RegistroProgreso.id)
            .join(DetalleRutina, RegistroProgreso.detalle_rutina_id == DetalleRutina.id)
            .where(DetalleRutina.rutina_id == rutina_id)
            .limit(1)
        )
        return self.db.scalars(stmt).first() is not None
